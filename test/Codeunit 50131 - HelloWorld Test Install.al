codeunit 50131 "HelloWorld Test Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        TestSuite: Codeunit "Test Suite";
    begin
        TestSuite.Create('HelloWorld', '50132..50132');
    end;
}