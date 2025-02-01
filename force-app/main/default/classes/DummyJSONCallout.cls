/*
 * DummyJSONCallout Class Description:
 * 
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context) 
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data) 
 * and POST (to send data) operations.
 * 
 * Overview of HTTP Callouts:
 * 
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts, 
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides 
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which 
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 * 
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 * 
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */
/* 
	 * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID. 
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
	 * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
	 * This callout method should work in triggers
	 * 
     * @param dummyUserId The ID of the user in the external system to fetch data for.
     */


	
public with sharing class DummyJSONCallout {
	@future(callout=true)
	public static void getDummyJSONUserFromIdFuture(String dummyUserId) {
		getDummyJSONUserFromId(dummyUserId);
	}

	@future(callout=true)
	public static void callPostCreateDummyJSONUserFuture(String contactId) {
		postCreateDummyJSONUser(contactId);
	}

	public static void getDummyJSONUserFromId(string dummyUserId){
			Http http = new Http();
			HttpRequest request = new HttpRequest();
			request.setEndpoint('callout:DummyJsonUser' + dummyUserId);   // Set the endpoint URL. Use direct URL or for best practices use Named Credential.
			request.setMethod('GET');			// Set the HTTP method to GET.
			HttpResponse response = http.send(request); 	

			if (response.getStatusCode() == 200) {			  // Send the HTTP request and get the response.
				String responseBody = response.getBody();     // Parse the JSON response
				Map<String, Object> jsonData = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
				
				Contact contact = createContactFromJson(jsonData);    // Create or update the contact based on DummyJSON_Id__c
				upsert contact DummyJSON_Id__c;	
		}
	}


@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static Contact createContactFromJson(Map<String, Object> jsonData) {
		if (jsonData == null || jsonData.isEmpty()) {
            throw new IllegalArgumentException('JSON data cannot be null or empty.'); 
				}					// If the HTTP response code is successful, parse the JSON response and update the contact.// Deserialize the JSON string into map of primitive data types.
			
			// Deserialize the address from the JSON response.
				Contact contact = new Contact();
				contact.DummyJSON_Id__c = String.valueOf(jsonData.get('id'));
				contact.FirstName = String.valueOf(jsonData.get('firstName'));
				contact.LastName = String.valueOf(jsonData.get('lastName'));		// Set the contact fields from the JSON response.
				contact.Email = String.valueOf(jsonData.get('email'));
				contact.Phone = String.valueOf(jsonData.get('phone'));
				contact.Birthdate = jsonData.containsKey('birthDate') 
						? Date.valueOf(String.valueOf(jsonData.get('birthDate'))) 
						: null;	
				
			if(jsonData.containsKey('address') && jsonData.get('address') !=null){
				Map<String, Object> jsonAddress = (Map<String, Object>) jsonData.get('address');
				contact.MailingStreet = String.valueOf(jsonAddress.get('address'));// Set the address fields on the contact.
				contact.MailingCity = String.valueOf(jsonAddress.get('city'));
				contact.MailingPostalCode = String.valueOf(jsonAddress.get('postalCode'));
				contact.MailingState = String.valueOf(jsonAddress.get('state'));
				contact.MailingCountry = String.valueOf(jsonAddress.get('country'));
				}		
			
		return contact;
			}

/*	 * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to create or update a user based on the provided Salesforce Contact ID.
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
	 * Salesforce Contact should be used to generate the JSON payload
	 * Fields: Id, FirstName, LastName, Email, Phone
	 * This callout method should work in triggers
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param contactId The Salesforce Contact ID used to generate the JSON payload for the external system.
	*/
	public static void postCreateDummyJSONUser(String contactId) {
		try {					
			Contact contact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :contactId LIMIT 1];
	
			if (contact == null) {
				return;
			}
		
		String payload = generateDummyJsonUserPayload(contact.Id);	// Generate JSON payload

			Http http = new Http();// Create HTTP request to send.
			HttpRequest request = new HttpRequest();
			request.setEndpoint('callout:DummyJsonUser' + 'add');// Set the endpoint URL. Use direct URL or for best practices use Named Credential.
			request.setMethod('POST');
			request.setHeader('Content-Type', 'application/json');
			request.setBody(payload); // Set the body using generateDummyJsonUserPayload method.
	
			HttpResponse response = http.send(request);
			// Set the HTTP method to POST.
	
			if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
				contact.DummyJSON_Last_Updated__c = DateTime.now();     // If the HTTP response code is successful, update the contact.
				update contact;
			} else {
				System.debug('Error: HTTP Response ' + response.getStatus() + ' - ' + response.getBody());	// Send the HTTP request and get the response.
			}
		} catch (Exception e) {
			System.debug('Error during HTTP callout: ' + e.getMessage());
		}

		} 
	
	
/*	 * Question 4
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for user creation or update.
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
	 * 
	 * Fields from Salesforce Contact used to generate JSON payload:
	 * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
	 * 
     * Documentation: https://dummyjson.com/docs/users

     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
     * @return String The JSON string payload that represents the Contact's details.
*/

@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	
	private static String generateDummyJsonUserPayload(String contactId){ // Query the contact to get the field values to generate the JSON payload.
	   
		Contact contact = [SELECT Id, FirstName, LastName, Email, Phone FROM  Contact WHERE Id = :contactId];
		
		Map<String, Object> payload = new Map<String, Object>();	// Create a map of the field values.
        payload.put('salesforceId', contact.Id);
        payload.put('firstName', contact.FirstName);// Make sure to check that required contacts fields have a value. Default the value to unknown if it does not exists.
        payload.put('lastName', contact.LastName);
        payload.put('email', contact.Email);
        payload.put('phone', contact.Phone);
						// Integration data can change over time. It is a best practice to add safeguards/validation to ensure the integration does not break.
        return JSON.serialize(payload);// Serialize the map into a JSON string.
    }
}
