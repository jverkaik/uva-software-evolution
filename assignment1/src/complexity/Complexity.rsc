module complexity::Complexity

import Prelude;

import util::Math;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import model::MetricTypes;
import model::CodeLineModel;
import model::CodeUnitModel;

import Util;
import Conversion;

import complexity::CyclomaticComplexity;
import complexity::Conversion;

alias ComplexityMetric = map[ComplexityRiskEvaluation complexityRiskEvaluation, real percentage];

//Public Functions

public ComplexityMetric projectComplexity(CodeUnitModel model)
{
	set[Unit] units = range(model);

	ComplexityMetric complexityPie = complexityPie(units);
	
	return complexityPie;
}

public ComplexityMetric complexityPie(set[Unit] units)
{	
	map[ComplexityRiskEvaluation, list[Unit]] groupedUnitsPerRisk = groupedUnitsPerRisk(units);
	
	LOC totalLinesOfCode = size(units) > 0 ? linesOfCodeOfUnitList(units) : 1;
	
	LOC simpleLines = size(units) > 0 ? linesOfCodeOfUnitList(groupedUnitsPerRisk[simple()]) : 1;
	LOC moreComplexLines = size(units) > 0 ? linesOfCodeOfUnitList(groupedUnitsPerRisk[moreComplex()]) : 0;
	LOC complexLines = size(units) > 0 ? linesOfCodeOfUnitList(groupedUnitsPerRisk[complex()]) : 0;
	LOC untestableLines = size(units) > 0 ? linesOfCodeOfUnitList(groupedUnitsPerRisk[untestable()]) : 0;	
	
	ComplexityMetric result = (
								simple() : toReal(simpleLines) / toReal(totalLinesOfCode),
								moreComplex() : toReal(moreComplexLines) / toReal(totalLinesOfCode),
								complex() : toReal(complexLines) / toReal(totalLinesOfCode),
								untestable() : toReal(untestableLines) / toReal(totalLinesOfCode)
								);
	
	return result;
}

public void printComplexity(ComplexityMetric complexityPie)
{
	println("COMPLEXITY");
	
	printCCTable();
	
	printRankTable(complexityPie);
}
//Private Functions

private ComplexityRiskEvaluation complexityRiskForUnit(Unit unit)
{
	CC cc = cyclomaticComplexityForUnit(unit);
		
	return convertCCToComplexityRiskEvalutation(cc);
}

private CC cyclomaticComplexityForUnit(Unit unit)
{
	return cyclomaticComplexityForStatement(unit.statement);
}

private map[ComplexityRiskEvaluation, list[Unit]] groupedUnitsPerRisk(list[Unit] units) = groupedUnitsPerRisk(toSet(units));

private map[ComplexityRiskEvaluation, list[Unit]] groupedUnitsPerRisk(set[Unit] units)
{
	list[tuple [Unit, ComplexityRiskEvaluation]] complexityPerUnit = [];
	
	for (unit <- units)
	{
		complexityPerUnit += <unit, complexityRiskForUnit(unit)>;
	}

	list[Unit] simpleUnits = [];
	list[Unit] moreComplexUnits = [];
	list[Unit] complexUnits = [];
	list[Unit] untestableUnits = [];
	
	for (<u, c> <- complexityPerUnit)
	{
		switch (c)
		{
			case simple() : simpleUnits += u;
			case moreComplex() : moreComplexUnits += u;
			case complex() : complexUnits += u;
			case untestable() : untestableUnits += u;
			default : fail; 
		}
	}
	
	return (simple() : simpleUnits, 
			moreComplex() : moreComplexUnits, 
			complex() : complexUnits, 
			untestable() : untestableUnits
			);
}

//Tests
public list[bool] allTests() = [
								testComplexityPieWithoutCommentsAndEmptyLines(),
								testComplexityPieWithCommentsAndEmptyLines(),
								testSumComplexityPieWithoutCommentsAndEmptyLinesIsOne(),
								testSumComplexityPieWithCommentsAndEmptyLinesIsOne(),
								testRankWithoutCommentsAndEmptyLines(),
								testRankWithCommentsAndEmptyLines()
								];


test bool testSumComplexityPieWithoutCommentsAndEmptyLinesIsOne()
{
	loc file = |project://testSource/src/TestComplexityWithoutCommentsAndEmptyLines.java|;
	M3 m3Model = createM3FromEclipseFile(file);
	Declaration declaration = createAstFromFile(file, false);
	
	CodeLineModel codeLineModel = createCodeLineModel(m3Model);
	CodeUnitModel codeUnitModel = createCodeUnitModel(m3Model, codeLineModel, {declaration});

	map[ComplexityRiskEvaluation, real] complexityPie = complexityPie(range(codeUnitModel));
	
	real result = sum(range(complexityPie));
	
	return result > 0.9999 && result < 1.00001;
}

test bool testSumComplexityPieWithCommentsAndEmptyLinesIsOne()
{
	loc file = |project://testSource/src/TestComplexityWithCommentsAndEmptyLines.java|;
	M3 m3Model = createM3FromEclipseFile(file);
	Declaration declaration = createAstFromFile(file, false);
	
	CodeLineModel codeLineModel = createCodeLineModel(m3Model);
	CodeUnitModel codeUnitModel = createCodeUnitModel(m3Model, codeLineModel, {declaration});

	map[ComplexityRiskEvaluation, real] complexityPie = complexityPie(range(codeUnitModel));
	
	real result = sum(range(complexityPie));
	
	return result > 0.9999 && result < 1.00001;
}

test bool testComplexityPieWithoutCommentsAndEmptyLines()
{
	loc file = |project://testSource/src/TestComplexityWithoutCommentsAndEmptyLines.java|;
	M3 m3Model = createM3FromEclipseFile(file);
	Declaration declaration = createAstFromFile(file, false);
	
	CodeLineModel codeLineModel = createCodeLineModel(m3Model);
	CodeUnitModel codeUnitModel = createCodeUnitModel(m3Model, codeLineModel, {declaration});

	map[ComplexityRiskEvaluation, real] complexityPie = complexityPie(range(codeUnitModel));

	map[ComplexityRiskEvaluation, real] reference = (
													simple() : 10.0 / 77.0, 
													moreComplex() : 17.0 / 77.0, 
													complex() : 50.0 / 77.0, 
													untestable() : 0.0 / 77.0
													);
	
	return reference == complexityPie;
}

test bool testComplexityPieWithCommentsAndEmptyLines()
{
	loc file = |project://testSource/src/TestComplexityWithCommentsAndEmptyLines.java|;
	M3 m3Model = createM3FromEclipseFile(file);
	Declaration declaration = createAstFromFile(file, false);
	
	CodeLineModel codeLineModel = createCodeLineModel(m3Model);
	CodeUnitModel codeUnitModel = createCodeUnitModel(m3Model, codeLineModel, {declaration});

	map[ComplexityRiskEvaluation, real] complexityPie = complexityPie(range(codeUnitModel));

	map[ComplexityRiskEvaluation, real] reference = (
													simple() : 10.0 / 77.0, 
													moreComplex() : 17.0 / 77.0, 
													complex() : 50.0 / 77.0, 
													untestable() : 0.0 / 77.0
													);
	
	return reference == complexityPie;
}

test bool testRankWithoutCommentsAndEmptyLines()
{	
	loc file = |project://testSource/src/TestComplexityWithoutCommentsAndEmptyLines.java|;
	M3 m3Model = createM3FromEclipseFile(file);
	Declaration declaration = createAstFromFile(file, false);
	
	CodeLineModel codeLineModel = createCodeLineModel(m3Model);
	CodeUnitModel codeUnitModel = createCodeUnitModel(m3Model, codeLineModel, {declaration});
	
	ComplexityMetric pie = projectComplexity(codeUnitModel);
	Rank rank = convertPieToRank(pie);
	
	return rank == minusMinus();
}

test bool testRankWithCommentsAndEmptyLines()
{	
	loc file = |project://testSource/src/TestComplexityWithCommentsAndEmptyLines.java|;
	M3 m3Model = createM3FromEclipseFile(file);
	Declaration declaration = createAstFromFile(file, false);
	
	CodeLineModel codeLineModel = createCodeLineModel(m3Model);
	CodeUnitModel codeUnitModel = createCodeUnitModel(m3Model, codeLineModel, {declaration});
	
	ComplexityMetric pie = projectComplexity(codeUnitModel);
	Rank rank = convertPieToRank(pie);
	
	return rank == minusMinus();
}