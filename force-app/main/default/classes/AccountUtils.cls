public with sharing class AccountUtils {
  public static List<Account> accountsByState(String billingState) {
    System.debug('accountsByState!');
    return [SELECT Id, Name FROM Account WHERE BillingState = :billingState];
  }
}
