@isTest
private class AccountTriggerTest {
  @isTest
  static void TestCreateAccounts() {
    // Arrange
    // Create 200 new Accounts
    List<Account> accts = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
      Account acct = new Account(Name = 'Test Account' + String.valueOf(i),  BillingState = 'CA');
      accts.add(acct);
    }

    // Act
    Test.startTest();
    insert accts;
    Test.stopTest();

    // Assert
    List<Account> verifyAccts = [SELECT Id, ShippingState, BillingState FROM Account];
    System.assertEquals(200, verifyAccts.size());
    for(Account a : verifyAccts) {
      System.assertEquals('CA', a.ShippingState);
      System.assertEquals('CA', a.BillingState);
    }
  }
}