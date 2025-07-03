flutter test --reporter=compact > test_output.txt 
grep -E '^(FAILED|Error|EXCEPTION)' -A 10 test_output.txt > failed_tests.txt