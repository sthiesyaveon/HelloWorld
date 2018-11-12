codeunit 50130 "HelloWorld TestRunner"
{
    procedure RunTests(TestResultFileName: Text)
    var
        TestRunner: Codeunit "CAL Command Line Test Runner";
        TestManagement: Codeunit "CAL Test Management";
    begin
        AddCodeunit(Codeunit::"HelloWorld Tests");
        TestRunner.Run();
        TestManagement.ExportTestResults(TestResultFileName, false, true);
    end;

    local procedure AddCodeunit("Test Codeunit ID": Integer)
    var
        CALTestEnabledCodeunit: Record "CAL Test Enabled Codeunit";
    begin
        CALTestEnabledCodeunit.Init();
        CALTestEnabledCodeunit."Test Codeunit ID" := "Test Codeunit ID";
        CALTestEnabledCodeunit.Insert();
    end;
}