/**
 * Mock class for branch and pipeline tests. It has no business logic.
 */
public with sharing class MockFeatureService {

    public static String greet(String name) {
        if (String.isBlank(name)) {
            return 'Hello, world';
        }
        return 'Hello, ' + name;
    }
}
