module Main

import Prelude;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import model::PackageModel;
import model::PackageModelTests;
import model::CodeLineModel;
import model::CloneModel;

import type1::Type1;
import type1::Type1Tests;
import type2::Type2;
import type2::Type2Tests;
import type3::Type3;
import type3::Type3Tests;

import normalization::Normalization;
import normalization::Config;

import type1::Config;
import type2::Config;
import type3::Config;

import visualisation::HTMLTests;
import visualisation::Visualisation;


public list[loc] projects()
{
	return [|project://smallsql0.21_src|, |project://hsqldb-2.3.1|, |project://testCloneSource|];
}

public void detectClones(loc project)
{
	println("Building M3 model for project...");
	M3 m3Model = createM3FromEclipseProject(project);

	println("Building CodeLineModel...");
	CodeLineModel codeLineModel = createCodeLineModel(m3Model);
	
	println("Building PackageModel...");
	PackageModel packageModel = createPackageModel(m3Model, codeLineModel);

	//Type 1
//	println("Building cloneModelType1...");
//	CloneModel cloneModelType1 = type1::Type1::clonesInProject(codeLineModel);
//
//	println("Building visualisation Type1..");
//	createVisualisation(project.authority, packageModel, codeLineModel, cloneModelType1, type1());
	
	//Prepare Type1 and Type2
	println("Preparing for Type2 and Type3...");
	
	println("Building AST model for project...");
	set[Declaration] declarations = createAstsFromEclipseProject(project, false);
	
	println("Extracting normalized subtrees..");
	map[node, set[loc]] normalizedSubtrees = findAllRelevantNormalizedSubtrees(declarations, normalization::Config::defaultConfiguration);
	
	int numberOfMinumumLines = 14;
	
	//Type 2
	println("Building cloneModelType2...");
	Config config2 = type2::Config::defaultConfiguration;
	config2.minimumNumberOfLines = numberOfMinumumLines;
	CloneModel cloneModelType2 = type2::Type2::clonesInProjectFromNormalizedSubtrees(normalizedSubtrees, codeLineModel, config2);

	println("Building visualisation Type2..");
	createVisualisation(project.authority, packageModel, codeLineModel, cloneModelType2, type2());
	
	////Type 3
	//println("Building cloneModelType3..");
	//Config config3 = type3::Config::defaultConfiguration;
	//config3.minimumNumberOfLines = numberOfMinumumLines;
	//CloneModel cloneModelType3 = type3::Type3::clonesInProjectFromNormalizedSubtrees(normalizedSubtrees, codeLineModel, config3);
	//
	//println("Building visualisation Type3..");
	//createVisualisation(project.authority, packageModel, codeLineModel, cloneModelType3, type3());
}

//Test Functions
public void runAllTests()
{
	list[tuple[str,list[bool]]] tests = [
								<"CodeLineModel.rsc Tests", model::CodeLineModel::allTests()>,
								<"PackageModelTests.rsc Tests", model::PackageModelTests::allTests()>,
								<"HTMLTests.rsc Tests", visualisation::HTMLTests::allTests()>,
								<"Type1Tests.rsc Tests", type1::Type1Tests::allTests()>,
								<"Type2Tests.rsc Tests", type2::Type2Tests::allTests()>,
								<"Type3Tests.rsc Tests", type3::Type3Tests::allTests()>
								];

	int numberOfFailedTests = 0;
	int numberOfPassedTests = 0;
	
	println("-----------------------------------------------------------");
	
	for (<name, subTests> <- tests)
	{
		tuple[int passed, int failed] result = runTests(subTests);
		numberOfPassedTests += result.passed;
		numberOfFailedTests += result.failed;
		println("<name> : <result.passed> passed, <result.failed> failed");
	}
	
	println("-----------------------------------------------------------");
	println("TEST REPORT:<numberOfPassedTests> passed, <numberOfFailedTests> failed");
	println("-----------------------------------------------------------");
}

//Function to run a list of tests
public tuple[int passed, int failed] runTests(list[bool] tests)
{
	int numberOfTests = size(tests);
	int passedTests = size([t | t <- tests, t == true]);
	return <passedTests, numberOfTests - passedTests>;
}




//Clone original = clone(1, 1, |file:///|, [
//						codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	7, 0, "	void sumProd1a(int n){"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	8, 0, "	double sum = 0.0;//C1"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	9, 0, "	double prod = 1.0;"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	10, 0, "	for (int i = 1; i \<= n; i++)"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	11, 0, "		{sum = sum + i;"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	12, 0, "		prod = prod * i;"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	13, 0, "		foo(sum, prod); }}")
//]);
//
//Clone clone1A = clone(1, 2, |file:///|, [
//						codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	16, 0, "	void sumProd1a(int n){"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	17, 0, "	double sum = 0.0;//C1"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	18, 0, "	double prod = 1.0;"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	19, 0, "	for (int i = 1; i \<= n; i++)"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	20, 0, "			{sum = sum + i;"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	21, 0, "			prod = prod * i;"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/Originaland1Aand3C.java|,
//	22, 0, "			foo(sum, prod); }}")
//]);
//
//Clone clone1B = clone(1, 3, |file:///|, [
//						codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1B.java|,
//	5, 0, "	void sumProd1a(int n){"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1B.java|,
//	6, 0, "	double sum = 0.0;//C1\'"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1B.java|,
//	7, 0, "	double prod = 1.0;//C"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1B.java|,
//	8, 0, "	for (int i = 1; i \<= n; i++)"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1B.java|,
//	9, 0, "		{sum = sum + i;"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1B.java|,
//	10, 0, "		prod = prod * i;"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1B.java|,
//	11, 0, "		foo(sum, prod); }}")
//]);
//
//Clone clone1C = clone(1, 4, |file:///|, [
//						codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1C.java|,
//	6, 0, "	void sumProd1a(int n){"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1C.java|,
//	7, 0, "	double sum = 0.0;//C1\'"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1C.java|,
//	8, 0, "	double prod = 1.0;//C"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1C.java|,
//	9, 0, "	for (int i = 1; i \<= n; i++) {"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1C.java|,
//	10, 0, "		sum = sum + i;"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1C.java|,
//	11, 0, "		prod = prod * i;"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage/CloneType1C.java|,
//	12, 0, "		foo(sum, prod); }}")
//]);
//
//Clone clone2C = clone(1, 5, |file:///|, [
//						codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage2/child/CloneType2C.java|,
//	6, 0, "	void sumProd1a(int n){"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage2/child/CloneType2C.java|,
//	7, 0, "	double sum = 0;//C1\'"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage2/child/CloneType2C.java|,
//	8, 0, "	double prod = 1;//C"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage2/child/CloneType2C.java|,
//	9, 0, "	for (int i = 1; i \<= n; i++) {"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage2/child/CloneType2C.java|,
//	10, 0, "		sum = sum + i;"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage2/child/CloneType2C.java|,
//	11, 0, "		prod = prod * i;"),
//	codeLine(|file:///Users/tonheijligers/Documents/WorkspaceSE/uva-software-evolution/testCloneSource/src/clonePackage2/child/CloneType2C.java|,
//	12, 0, "		foo(sum, prod); }}")
//]);
//
//public CloneModel myCloneClasses = (
//	0:[original, clone1A, clone1B, clone1C, clone2C]
//);

