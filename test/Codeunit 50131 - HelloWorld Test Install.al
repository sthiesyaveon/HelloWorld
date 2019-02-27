codeunit 50131 "HelloWorld Test Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        TestSuite: Codeunit "Test Suite";
    begin
        TestSuite.Create('DEFAULT', '50132..50132', false);
    end;
}