codeunit 50131 "HelloWorld Test Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        ALTestSuite: Record "AL Test Suite";
        SuiteName: Code[10];
    begin
        SuiteName := 'DEFAULT';
        if not ALTestSuite.Get(SuiteName) then begin
            TestSuiteMgt.CreateTestSuite(SuiteName);
            Commit();
            ALTestSuite.Get(SuiteName);
        end;
        TestSuiteMgt.SelectTestMethodsByRange(ALTestSuite, '50133..50133');
    end;
}