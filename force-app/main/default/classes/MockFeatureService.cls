/**
 * Mock class for branch and pipeline tests. It has no business logic.
 */
public with sharing class MockFeatureService {

    public static String greet(String name) {
        return 'Hello ' + (String.isBlank(name) ? 'team' : name) + ', we are working in Lytx';
    }
}
