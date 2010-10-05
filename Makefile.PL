use inc::Module::Install;
name 'Test-Fixture-DBI-Console';
all_from 'lib/Test/Fixture/DBI/Console.pm';

requires 'DBI' => 0;
requires 'Term::ReadLine' => 0;
requires 'Test::Fixture::DBI' => '0.03';
requires 'Test::mysqld'       => '0.11';

install_script 'script/test_fixture_console';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
