public class ContactsListWithController {
  private String sortOrder = 'LastName';

  public List<Contact> getContacts() {
    List<String> fields = new List<String>{ 'Id', 'FirstName', 'LastName', 'Title', 'Email' };
    Query contactQuery = (new Query()).source(Contact.getSObjectType()).pick(fields).orderBy(sortOrder).restrict(10);
    List<Contact> contacts = (List<Contact>) (new Repository()).get(contactQuery);

    return contacts;
  }

  public void sortByLastName() {
    this.sortOrder = 'LastName';
  }

  public void sortByFirstName() {
    this.sortOrder = 'FirstName';
  }
}