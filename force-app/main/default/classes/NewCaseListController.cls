public class NewCaseListController {
  public List<Case> getNewCases() {
    List<String> fields = new List<String>{ 'Id', 'CaseNumber' };
    Query caseQuery = (new Query()).source(Case.getSObjectType()).pick(fields).condition('Status', '=', 'New');
    // return (List<Case>) (new Repository()).get(caseQuery);
    return [
      SELECT Id, CaseNumber
      FROM Case
      WHERE Status = 'New'
    ];
  }
}