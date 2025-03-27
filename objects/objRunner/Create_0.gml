/// @description Start Framework
/// This is the entry point for the frameowork execution.
testFramework = new TestFrameworkRun();

// ################# TEST SUITE REGISTRATION #################


//// Register your test suites here...
testFramework.addSuite(BasicEscapeCharacterTestSuite);

testFramework.addSuite(BasicCompoundAssignmentAccessorsTestSuite);

testFramework.addSuite(OptimizerConstantFoldingTestSuite);
testFramework.addSuite(OptimizerConstantPropagationTestSuite);
testFramework.addSuite(OptimizerUnreachableCodeTestSuite);

testFramework.addSuite(BasicConstructorTestSuit);
testFramework.addSuite(BasicUnaryUpdateExpressions);
testFramework.addSuite(BasicAccessorExpressionsTestSuite);
testFramework.addSuite(BasicStatementExpressionsTestSuite);

testFramework.addSuite(BasicArrayTestSuite);
testFramework.addSuite(BasicBase64TestSuite);
testFramework.addSuite(BasicDataStructuresGridTestSuite);
testFramework.addSuite(BasicDataStructuresListTestSuite);
testFramework.addSuite(BasicDataStructuresMapTestSuite);
testFramework.addSuite(BasicDataStructuresPriorityTestSuite);
testFramework.addSuite(BasicDataStructuresQueueTestSuite);
testFramework.addSuite(BasicDataStructuresStackTestSuite);
testFramework.addSuite(BasicDataTypesTestSuite);
testFramework.addSuite(BasicDateTimeTestSuite);
testFramework.addSuite(BasicFileTestSuite);
//testFramework.addSuite(BasicFiltersEffectsTestSuite);
testFramework.addSuite(BasicHandlesTestSuite);
testFramework.addSuite(BasicIniTestSuite);
testFramework.addSuite(BasicJsonTestSuite);
testFramework.addSuite(BasicMathTestSuite);
testFramework.addSuite(BasicMatrixTestSuite);
testFramework.addSuite(BasicNameofTestSuite);
testFramework.addSuite(BasicRandomTestSuite);
testFramework.addSuite(BasicScriptTestSuite);
testFramework.addSuite(BasicStringTestSuite);
testFramework.addSuite(BasicVariableTestSuite);

testFramework.addSuite(BasicSurfaceTestSuite);
testFramework.addSuite(BasicWeakRefsTestSuite);
testFramework.addSuite(ResourceAudioEffectsTestSuite);
testFramework.addSuite(ResourceAudioEmittersTestSuite);
testFramework.addSuite(ResourceAudioListenersTestSuite);
testFramework.addSuite(ResourceCameraTestSuite);
testFramework.addSuite(ResourceEventsTestSuite);
testFramework.addSuite(ResourceLayersTestSuite);


//// Async Tests
//testFramework.addSuite(BasicNetworkTestSuite);
//testFramework.addSuite(ResourceAudioSynchronisationTestSuite);
//testFramework.addSuite(ResourceAudioLoopPointsTestSuite);
//testFramework.addSuite(BasicTilemapTestSuite);
//testFramework.addSuite(BasicRoomTestSuite);
//testFramework.addSuite(BasicBufferTestSuite);
//testFramework.addSuite(BasicAudioTestSuite);
//testFramework.addSuite(ResourceAudioBuffersTestSuite);

//// unsafe to run currently
//testFramework.addSuite(ResourceTimeSourceTestSuite);
//testFramework.addSuite(ResourceSequenceTestSuite);
////testFramework.addSuite(ResourceAudioGroupsTestSuite);
////testFramework.addSuite(BasicShaderUniformsTestSuite);
////testFramework.addSuite(BasicShaderTestSuite);


// ###########################################################

testFramework.run(undefined, {});
