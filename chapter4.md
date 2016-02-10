#<center>4. TDD & Vendor Bundle</center>

<br/>

##4.1 Symfony best practices for reusable bundles

Previously, we got in touch with Sensio Generator Bundle. In this chapter we will attempt to come with an enhanced alternative to that bundle. The main motivation for developing a vendor bundle is code re-usability. Therefore, one of the most expected aspects is a well decoupled and extensible code.

 Before we start, let's highlight some of the Symfony best practices for reusable bundles.

> - A bundle should come with a test suite written with PHPUnit and stored under the Tests/ directory.
- The tests should cover at least 95% of the code base.
- All classes and functions must come with full PHPDoc.
- Extensive documentation should also be provided.

I developed my own flavor of good practices also, that I would like to share with you
> - The tests should cover <strike>at least 95%</strike> **100%** of the code base.
- Avoid dependencies, and when necessary keep them to the minimum, with maximum compatibility.
- When requesting configurations from the user, set default values whenever possible.

##4.2 Bundle skeleton

The bundle will be distributed using **composer**. The source code will be versioned using **git**. **PHPUnit** will be used as a unit testing framework.

- Create a new directory GeneratorBundle (or whatever you prefer) somewhere in your working directory but not within the application's directory.
- Create **composer.json**

````json
{
    "name": "emag/generator-bundle",
    "description": "Emag GeneratorBundle",
    "type": "symfony-bundle",
    "license": "MIT",
    "require": {
        "symfony/symfony": "~2.9|~3"
    },
    "require-dev": {
        "phpunit/phpunit": ">=4.4"
    },
    "autoload": {
        "psr-4": {
            "Emag\\GeneratorBundle\\": "",
            "exclude-from-classmap": [
                "/Tests/"
            ]
        }
    }
}
````

Run `composer install`. composer will install the required components under the **vendor** directory.

- Create **.gitignore**

````
vendor/
composer.lock
phpunit.xml
````

- Create **phpunit.xml.dist**

````xml
<?xml version="1.0" encoding="UTF-8"?>

<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="http://schema.phpunit.de/4.1/phpunit.xsd"
         backupGlobals="false"
         colors="true"
         bootstrap="vendor/autoload.php">
    <testsuites>
        <testsuite name="Emag GeneratorBundle Test Suite">
            <directory>./Tests/</directory>
        </testsuite>
    </testsuites>

    <filter>
        <whitelist>
            <directory>./</directory>
            <exclude>
                <directory>./Resources</directory>
                <directory>./Tests</directory>
                <directory>./vendor</directory>
            </exclude>
        </whitelist>
    </filter>

    <logging>
        <log type="coverage-text" target="php://stdout" showUncoveredFiles="true"/>
    </logging>
</phpunit>
````

##4.3 TDD

###4.3.1 What is TDD?

TDD stands for Test-Driven Development. The basic idea is very simple: write tests before writing production code.

We are not going to study TDD in depth here. There is plenty of material about the subject, you can start by the [wikipedia](https://en.wikipedia.org/wiki/Test-driven_development) page about TDD. The process may seem awkward and counter-intuitive at first. But once you get used to it, you will start seeing the benefits it will bring to your code quality, and to your productivity.

A complete test-driven development cycle consists on the following sequence

1. Add a test
2. Run all tests and see if the new one fails
3. Write some code
4. Run tests
5. Refactor code
6. Repeat

In the following section we will go through a set of TDD cycles. In each cycle we will set an expectation in natural language then apply the TDD sequence until the expectation is fulfilled.

###4.3.2 TDD cycles

###4.3.2.1 Generate route for view action

Given an entity called **TestEntity** within a bundle **TestBundle**. The generated route for the **view** action should have:  
path: **/test/testentity/{id}/view**  
controller: **TestBundle:TestEntity:view**  
methods: **[GET]**  

#####Cycle 1.1. Add a test

- Create **Tests/Generator/RouteGeneratorTest.php**

````php
<?php

namespace Emag\GeneratorBundle\Tests\Generator;

class RouteGeneratorTest extends \PHPUnit_Framework_TestCase
{

    public function testGenerateViewRoute()
    {
        $bundleMock = $this
                ->getMockBuilder("Symfony\Component\HttpKernel\Bundle\BundleInterface")
                ->getMock();
        $bundleMock
                ->expects($this->any())
                ->method('getName')
                ->will($this->returnValue('TestBundle'));

        $metadataMock = $this
                ->getMockBuilder("Doctrine\Common\Persistence\Mapping\ClassMetadata")
                ->getMock();
        $metadataMock
                ->expects($this->any())
                ->method('getName')
                ->will($this->returnValue('TestEntity'));

        $routeGenerator = new \Emag\GeneratorBundle\Generator\RouteGenerator();

        $route = $routeGenerator->getRoute($bundleMock, $metadataMock, 'view');

        $this->assertEquals('/test/testentity/{id}/view', $route->getPath());
        $this->assertEquals(
                array('_controller' => 'TestBundle:TestEntity:view'), $route->getDefaults()
        );
        $this->assertEquals(array('GET'), $route->getMethods());
    }

}
````

#####Cycle 1.2. Run all tests and see if the new one fails

````bash
$ ./vendor/phpunit/phpunit/phpunit

PHP Fatal error:  Class 'Emag\GeneratorBundle\Generator\RouteGenerator' not found in  
 /GeneratorBundle/Tests/Generator/RouteGeneratorTest.php on line 22
````
This is indeed a failing tests. In the future we will omit this kind of tests because of its obviousness.

#####Cycle 1.3. Write some code
- Create **Generator/RouteGenerator.php**

````php
<?php

namespace Emag\GeneratorBundle\Generator;

use Doctrine\Common\Persistence\Mapping\ClassMetadata;
use Symfony\Component\HttpKernel\Bundle\BundleInterface;
use Symfony\Component\Routing\Route;

class RouteGenerator
{

    /**
     * @param BundleInterface $bundle
     * @param ClassMetadata $metadata
     * @param string $action
     * @return Route
     */
    public function getRoute(BundleInterface $bundle, ClassMetadata $metadata, $action)
    {
        $route = null;
        switch ($action) {
            case 'view':
                $route = $this->createViewRoute($bundle, $metadata, $action);
                break;
        }
        return $route;
    }

    /**
     * @param BundleInterface $bundle
     * @param ClassMetadata $metadata
     * @param string $action
     * @return Route
     */
    protected function createViewRoute(BundleInterface $bundle, ClassMetadata $metadata, $action)
    {
        $route = new Route($this->getViewPath($bundle, $metadata, $action));
        $route
                ->setMethods(array('get'))
                ->setDefaults(
                        array('_controller' => $this->getControllerAction($bundle, $metadata, $action))
        );
        return $route;
    }

    /**
     *
     * @param BundleInterface $bundle
     * @param ClassMetadata $metadata
     * @param string $action
     * @return string
     */
    protected function getViewPath(BundleInterface $bundle, ClassMetadata $metadata, $action)
    {
        return sprintf('/%s/%s/{id}/%s', $this->getRoutePrefix($bundle), strtolower($metadata->getName()), $action);
    }

    /**
     *
     * @param BundleInterface $bundle
     * @return string
     */
    protected function getRoutePrefix(BundleInterface $bundle)
    {
        return strtolower(str_replace('Bundle', '', $bundle->getName()));
    }

    /**
     *
     * @param BundleInterface $bundle
     * @param ClassMetadata $metadata
     * @param type $action
     * @return string
     */
    protected function getControllerAction(BundleInterface $bundle, ClassMetadata $metadata, $action)
    {
        return $bundle->getName() . ':' . $metadata->getName() . ':' . $action;
    }
}
````
#####Cycle 1.4. Run tests
````bash
$ ./vendor/phpunit/phpunit/phpunit

OK (1 test, 3 assertions)

Code Coverage Report:

 Summary:
  Classes: 100.00% (1/1)  
  Methods: 100.00% (5/5)  
  Lines:   100.00% (12/12)

\Emag\GeneratorBundle\Generator::RouteGenerator
  Methods: 100.00% ( 5/ 5)   Lines: 100.00% ( 12/ 12)
````

In the future we will omit this sequence unless there is something interesting about it.

###4.3.2.2 Throw an exception when given an invalid action

#####Cycle 2.1. Add a test
Add the following test to **Tests/Generator/RouteGeneratorTest.php**

````php
/**
 * @expectedException \InvalidArgumentException
 * @expectedExceptionMessage Invalid action invalid_action
 */
public function testGenerateInvalidAction()
{
    $bundleMock = $this
            ->getMockBuilder("Symfony\Component\HttpKernel\Bundle\BundleInterface")
            ->getMock();

    $metadataMock = $this
            ->getMockBuilder("Doctrine\Common\Persistence\Mapping\ClassMetadata")
            ->getMock();

    $routeGenerator = new \Emag\GeneratorBundle\Generator\RouteGenerator();

    $routeGenerator->getRoute($bundleMock, $metadataMock, 'invalid_action');
}
````
#####Cycle 2.2. Run all tests and see if the new one fails

````bash
$ ./vendor/phpunit/phpunit/phpunit
There was 1 failure:

1) Emag\GeneratorBundle\Tests\Generator\RouteGeneratorTest::testGenerateInvalidAction
Failed asserting that exception of type "\InvalidArgumentException" is thrown
````
#####Cycle 2.3. Write some code

Update `Emag\GeneratorBundle\Generator\RouteGenerator::getRoute` as following

````php
/**
 * @param BundleInterface $bundle
 * @param ClassMetadata $metadata
 * @param string $action
 * @return Route
 * @throws \InvalidArgumentException
 */
public function getRoute(BundleInterface $bundle, ClassMetadata $metadata, $action)
{
    $route = null;
    switch ($action) {
        case 'view':
            $route = $this->createViewRoute($bundle, $metadata, $action);
            break;
        default:
            throw new \InvalidArgumentException(sprintf("Invalid action %s", $action));
    }
    return $route;
}
````
#####Cycle 2.4. Run tests (pass)

###4.3.2.3 Generate route for edit action

Given an entity called **TestEntity** within a bundle **TestBundle**. The generated route for the **edit** action should have:  
path: **/test/testentity/{id}/edit**  
controller: **TestBundle:TestEntity:edit**  
methods: **[GET]**  

#####Cycle 3.1. Add a test

Add the following test to **Tests/Generator/RouteGeneratorTest.php**

````php
public function testGenerateEditRoute()
{
    $bundleMock = $this
            ->getMockBuilder("Symfony\Component\HttpKernel\Bundle\BundleInterface")
            ->getMock();
    $bundleMock
            ->expects($this->any())
            ->method('getName')
            ->will($this->returnValue('TestBundle'));

    $metadataMock = $this
            ->getMockBuilder("Doctrine\Common\Persistence\Mapping\ClassMetadata")
            ->getMock();
    $metadataMock
            ->expects($this->any())
            ->method('getName')
            ->will($this->returnValue('TestEntity'));

    $routeGenerator = new \Emag\GeneratorBundle\Generator\RouteGenerator();

    $route = $routeGenerator->getRoute($bundleMock, $metadataMock, 'edit');
    $this->assertEquals('/test/testentity/{id}/edit', $route->getPath());
    $this->assertEquals(
            array('_controller' => 'TestBundle:TestEntity:edit'), $route->getDefaults()
    );
    $this->assertEquals(array('GET'), $route->getMethods());
}
````

#####Cycle 3.2. Run all tests and see if the new one fails (it does)

#####Cycle 3.3. Write some code

Add a case statement to the switch in `Emag\GeneratorBundle\Generator\RouteGenerator::getRoute`

````
case 'edit':
    $route = $this->createEditRoute($bundle, $metadata, $action);
    break;
````

Add the following methods:

````php
/**
 * @param BundleInterface $bundle
 * @param ClassMetadata $metadata
 * @param string $action
 * @return Route
 */
protected function createEditRoute(BundleInterface $bundle, ClassMetadata $metadata, $action)
{
    $route = new Route($this->getEditPath($bundle, $metadata, $action));
    $route->setMethods(array('get'))
            ->setDefaults(array('_controller' => $this->getControllerAction($bundle, $metadata, $action)));
    return $route;
}

/**
 *
 * @param BundleInterface $bundle
 * @param ClassMetadata $metadata
 * @param string $action
 * @return string
 */
protected function getEditPath(BundleInterface $bundle, ClassMetadata $metadata, $action)
{
    return sprintf('/%s/%s/{id}/%s', $this->getRoutePrefix($bundle), strtolower($metadata->getName()), $action);
}
````

#####Cycle 3.4. Run tests (pass)

#####Cycle 3.5. Refactor code

In `Emag\GeneratorBundle\Generator\RouteGenerator` `getViewPath` and `getEditPath` are identical. That's a flagrant code duplication.  
Rename one of them to `getActionPath`, remove the other method, and update the calling code to call `getActionPath`.

Running the tests confirms that our refactoring didn't break anything.

In `Emag\GeneratorBundle\Tests\Generator\RouteGeneratorTest` `testGenerateViewRoute` and `testGenerateEditRoute` share identical code to create a bundle and metadata mocks. We will extract it in separate methods.

````php
private function createTestBundleMock()
{
    $bundleMock = $this
            ->getMockBuilder("Symfony\Component\HttpKernel\Bundle\BundleInterface")
            ->getMock();
    $bundleMock
            ->expects($this->any())
            ->method('getName')
            ->will($this->returnValue('TestBundle'));

    return $bundleMock;
}

private function createTestMetadataMock()
{
    $metadataMock = $this
            ->getMockBuilder("Doctrine\Common\Persistence\Mapping\ClassMetadata")
            ->getMock();
    $metadataMock
            ->expects($this->any())
            ->method('getName')
            ->will($this->returnValue('TestEntity'));

    return $metadataMock;
}
````

Update the previous creations of mocks to simple method calls.
````php
$bundleMock = $this->createTestBundleMock();

$metadataMock = $this->createTestMetadataMock();
````

###4.3.2.4 Generate route for save action

Given an entity called **TestEntity** within a bundle **TestBundle**. The generated route for the **save** action should have:  
path: **/test/testentity/{id}/save**  
controller: **TestBundle:TestEntity:save**  
methods: **[POST]**

#####Cycle 4.1. Add a test

Add the following test to **Tests/Generator/RouteGeneratorTest.php**

````php
public function testGenerateSaveRoute()
{
    $bundleMock = $this->createTestBundleMock();

    $metadataMock = $this->createTestMetadataMock();

    $routeGenerator = new \Emag\GeneratorBundle\Generator\RouteGenerator();

    $route = $routeGenerator->getRoute($bundleMock, $metadataMock, 'save');
    $this->assertEquals('/test/testentity/{id}/save', $route->getPath());
    $this->assertEquals(
            array('_controller' => 'TestBundle:TestEntity:save'), $route->getDefaults()
    );
    $this->assertEquals(array('POST'), $route->getMethods());
}
````

#####Cycle 4.2. Run all tests and see if the new one fails (it does)

#####Cycle 4.3. Write some code

Add a case statement for **save** to the switch in `Emag\GeneratorBundle\Generator\RouteGenerator::getRoute`

Add the corresponding method.

````php
/**
 * @param BundleInterface $bundle
 * @param ClassMetadata $metadata
 * @param string $action
 * @return Route
 */
protected function createSaveRoute(BundleInterface $bundle, ClassMetadata $metadata, $action)
{
    $route = new Route($this->getActionPath($bundle, $metadata, $action));
    $route->setMethods(array('post'))
            ->setDefaults(array('_controller' => $this->getControllerAction($bundle, $metadata, $action)));
    return $route;
}
````
#####Cycle 4.4. Run tests (pass)

#####Cycle 4.5. Refactor code

In `Emag\GeneratorBundle\Generator\RouteGenerator`, `createViewRoute` and `createEditRoute` are identical and `createSaveRoute` differs from them only by the route methods. We will extract the common logic in a separate method.

````php
/**
 * @param BundleInterface $bundle
 * @param ClassMetadata $metadata
 * @param string $action
 * @return Route
 */
protected function createActionRoute(BundleInterface $bundle, ClassMetadata $metadata, $action, $methods = array('get'))
{
    $route = new Route($this->getActionPath($bundle, $metadata, $action));
    $route->setMethods($methods)
            ->setDefaults(array('_controller' => $this->getControllerAction($bundle, $metadata, $action)));
    return $route;
}
````

The previously duplicated methods will just forward the call to the new method.

````php
protected function createViewRoute(BundleInterface $bundle, ClassMetadata $metadata, $action)
{
    return $this->createActionRoute($bundle, $metadata, $action);
}

protected function createEditRoute(BundleInterface $bundle, ClassMetadata $metadata, $action)
{
    return $this->createActionRoute($bundle, $metadata, $action);
}

protected function createSaveRoute(BundleInterface $bundle, ClassMetadata $metadata, $action)
{
    return $this->createActionRoute($bundle, $metadata, $action, array('post'));
}
````

###4.3.2.5 Generate route for save action

Given an entity called **TestEntity** within a bundle **TestBundle**. The generated route for the **new** action should have:  
path: **/test/testentity/new**  
controller: **TestBundle:TestEntity:new**  
methods: **[GET]**

#####Cycle 5.1. Add a test

Add the following test to **Tests/Generator/RouteGeneratorTest.php**

````php
public function testGenerateNewRoute()
{
    $bundleMock = $this->createTestBundleMock();

    $metadataMock = $this->createTestMetadataMock();

    $routeGenerator = new \Emag\GeneratorBundle\Generator\RouteGenerator();

    $route = $routeGenerator->getRoute($bundleMock, $metadataMock, 'new');
    $this->assertEquals('/test/testentity/{id}/new', $route->getPath());
    $this->assertEquals(
            array('_controller' => 'TestBundle:TestEntity:new'), $route->getDefaults()
    );
    $this->assertEquals(array('GET'), $route->getMethods());
}
````
#####Cycle 5.2. Run all tests and see if the new one fails (it does)

#####Cycle 5.3. Write some code

Add a case statement for **save** to the switch in `Emag\GeneratorBundle\Generator\RouteGenerator::getRoute`

Add the corresponding method.

````php
/**
 * @param BundleInterface $bundle
 * @param ClassMetadata $metadata
 * @param string $action
 * @return Route
 */
protected function createNewRoute(BundleInterface $bundle, ClassMetadata $metadata, $action)
{
    return $this->createActionRoute($bundle, $metadata, $action);
}
````
#####Cycle 5.4. Run tests (pass)

#####Cycle 5.5. Refactor code

In `Emag\GeneratorBundle\Tests\Generator\RouteGeneratorTest` `testGenerateViewRoute`, `testGenerateEditRoute`, `testGenerateSaveRoute` and `testGenerateNewRoute` are very similar and present the same logic. We will refactor them as following.

````php
private function generateAndAssertRoute($name, $expectedPath, $expectedDefaults, $expectedMethods)
{
    $bundleMock = $this->createTestBundleMock();
    $metadataMock = $this->createTestMetadataMock();

    $routeGenerator = new \Emag\GeneratorBundle\Generator\RouteGenerator();

    $route = $routeGenerator->getRoute($bundleMock, $metadataMock, $name);
    $this->assertEquals($expectedPath, $route->getPath());
    $this->assertEquals($expectedDefaults, $route->getDefaults());
    $this->assertEquals($expectedMethods, $route->getMethods());
}

public function testGenerateViewRoute()
{
    $this->generateAndAssertRoute(
            'view', //Expected name
            '/test/testentity/{id}/view', //Expected path
            array('_controller' => 'TestBundle:TestEntity:view'), //Expected defaults
            array('GET') //Expected methods
    );
}
````
Refactor the other tests as we did with `testGenerateViewRoute`.

###4.3.2.6 Generate route for create action

Given an entity called **TestEntity** within a bundle **TestBundle**. The generated route for the **create** action should have:  
path: **/test/testentity/create**  
controller: **TestBundle:TestEntity:create**  
methods: **[POST]**

#####Cycle 6.1. Add a test

Add the following test to **Tests/Generator/RouteGeneratorTest.php**

````php
public function testGenerateCreateRoute()
{
    $this->generateAndAssertRoute(
            'create', //Expected name
            '/test/testentity/{id}/create', //Expected path
            array('_controller' => 'TestBundle:TestEntity:create'), //Expected defaults
            array('POST') //Expected methods
    );
}
````
#####Cycle 6.2. Run all tests and see if the new one fails (it does)

#####Cycle 6.3. Write some code

Add a case statement for **create** to the switch in `Emag\GeneratorBundle\Generator\RouteGenerator::getRoute`

Add the corresponding method.

````php
/**
 * @param BundleInterface $bundle
 * @param ClassMetadata $metadata
 * @param string $action
 * @return Route
 */
protected function createCreateRoute(BundleInterface $bundle, ClassMetadata $metadata, $action)
{
    return $this->createActionRoute($bundle, $metadata, $action, array('post'));
}
````

#####Cycle 6.4. Run tests (pass)

#####Cycle 6.5. Refactor code

In `Emag\GeneratorBundle\Tests\Generator\RouteGeneratorTest` all the tests except `testGenerateInvalidAction` just calls `testGenerateInvalidAction` with different arguments. This is a prefect candidate to directly feed `testGenerateInvalidAction` by a data provider.

First, make `generateAndAssertRoute` public and add the following annotation to it

````
/**
 * @test
 * @dataProvider getExpectedRoutes
 */
public function generateAndAssertRoute(...
````

Then add the data provider method.

````php
public function getExpectedRoutes()
{
    return array(
        array(
            'view', //name
            '/test/testentity/{id}/view', //path
            array('_controller' => 'TestBundle:TestEntity:view'), //defaults
            array('GET') //methods
        ),
        array(
            'edit', //name
            '/test/testentity/{id}/edit', //path
            array('_controller' => 'TestBundle:TestEntity:edit'), //defaults
            array('GET') //methods
        ),
        array(
            'save', //name
            '/test/testentity/{id}/save', //path
            array('_controller' => 'TestBundle:TestEntity:save'), //defaults
            array('POST') //methods
        ),
        array(
            'new', //name
            '/test/testentity/{id}/new', //path
            array('_controller' => 'TestBundle:TestEntity:new'), //defaults
            array('GET') //methods
        ),
        array(
            'create', //name
            '/test/testentity/{id}/create', //path
            array('_controller' => 'TestBundle:TestEntity:create'), //defaults
            array('POST') //methods
        )
    );
}
````
###4.3.2.7 Generate route for delete action

Given an entity called **TestEntity** within a bundle **TestBundle**. The generated route for the **create** action should have:  
path: **/test/testentity/create**  
controller: **TestBundle:TestEntity:create**  
methods: **[POST]**

#####Cycle 7.1. Add a test
Add the following item to the data provider `getExpectedRoutes`  in **Tests/Generator/RouteGeneratorTest.php**

````
array(
    'delete', //name
    '/test/testentity/{id}/delete', //path
    array('_controller' => 'TestBundle:TestEntity:delete'), //defaults
    array('POST') //methods
)
````

#####Cycle 7.2. Run all tests and see if the new one fails (it does)

#####Cycle 7.3. Write some code

Add a case statement for **create** to the switch in `Emag\GeneratorBundle\Generator\RouteGenerator::getRoute`

Add the corresponding method.

````php
/**
 * @param BundleInterface $bundle
 * @param ClassMetadata $metadata
 * @param string $action
 * @return Route
 */
protected function createDeleteRoute(BundleInterface $bundle, ClassMetadata $metadata, $action)
{
    return $this->createActionRoute($bundle, $metadata, $action, array('post'));
}
````
#####Cycle 7.4. Run tests (pass)

###4.3.2.8 Generate template for view action

Given an entity called **TestEntity** within a bundle **TestBundle** and having one field named **testField**. The generated twig template for the **view** action should look like:  

````html
{% extends 'base.html.twig' %}
{% block body %}
    <table class="table-view" id="table-view-TestBundle-TestEntity">
        <tr>
            <th>testField</th>
            <td>{{TestEntity.testField}}</td>
        </tr>
    </table>
{% endblock %}
````

#####Cycle 8.1. Add a test

- Create **Tests/Generator/TemplateGeneratorTest.php**

````php
<?php

namespace Emag\GeneratorBundle\Tests\Generator;

class TemplateGeneratorTest extends \PHPUnit_Framework_TestCase
{

    public function testGenerateViewTemplate()
    {
        $twig = new \Twig_Environment(new \Twig_Loader_Filesystem(array(__DIR__ . '/../../Templates')));
        $templateGenerator = new \Emag\GeneratorBundle\Generator\TemplateGenerator($twig);

        $metadataMock = $this->createTestMetadataMock();

        $metadataMock->expects($this->any())
                ->method('getFieldNames')
                ->will($this->returnValue(array('testField')));

        $bundleMock = $this->createTestBundleMock();

        $template = $templateGenerator->getTemplate($bundleMock, $metadataMock, 'view');
        $expectedTemplate = <<<EOF
{% extends 'base.html.twig' %}
{% block body %}
    <table class="table-view" id="table-view-TestBundle-TestEntity">
        <tr>
            <th>testField</th>
            <td>{{TestEntity.testField}}</td>
        </tr>
    </table>
{% endblock %}
EOF;
        $this->assertEquals($expectedTemplate, $template);
    }

    private function createTestBundleMock()
    {
        $bundleMock = $this
                ->getMockBuilder("Symfony\Component\HttpKernel\Bundle\BundleInterface")
                ->getMock();
        $bundleMock
                ->expects($this->any())
                ->method('getName')
                ->will($this->returnValue('TestBundle'));

        return $bundleMock;
    }

    private function createTestMetadataMock()
    {
        $metadataMock = $this
                ->getMockBuilder("Doctrine\Common\Persistence\Mapping\ClassMetadata")
                ->getMock();
        $metadataMock
                ->expects($this->any())
                ->method('getName')
                ->will($this->returnValue('TestEntity'));

        return $metadataMock;
    }

}
````

#####Cycle 8.2. Run all tests and see if the new one fails (it does)

#####Cycle 8.3. Write some code

- Create **Generator/TemplateGenerator.php**

````php
<?php

namespace Emag\GeneratorBundle\Generator;

use Doctrine\Common\Persistence\Mapping\ClassMetadata;
use Symfony\Component\HttpKernel\Bundle\BundleInterface;

class TemplateGenerator
{

    /**
     * @var \Twig_Environment
     */
    private $twig;

    /**
     * @param \Twig_Environment $twig
     */
    public function __construct(\Twig_Environment $twig)
    {
        $this->twig = $twig;
    }

    /**
     * @param ClassMetadata $metadata
     * @param string $action
     * @return string
     */
    public function getTemplate(BundleInterface $bundle, ClassMetadata $metadata, $action)
    {
        $template = null;
        switch ($action) {
            case 'view':
                $template = $this->createViewTemplate($bundle, $metadata, $action);
                break;
        }
        return $template;
    }

    /**
     * @param ClassMetadata $metadata
     * @param string $action
     * @return string
     */
    protected function createViewTemplate(BundleInterface $bundle, ClassMetadata $metadata, $action)
    {
        return $this->twig->render($this->getTemplateName($action), array('metadata' => $metadata, 'bundle' => $bundle));
    }

    /**
     * @param string $action
     * @return string
     */
    protected function getTemplateName($action)
    {
        return sprintf('views/%s.html.twig.twig', $action);
    }

}
````

- Create **Templates/views/view.html.twig.twig**

````html
{{ "{% extends 'base.html.twig' %}" }}
{{ "{% block body %}" }}
    <table class="table-view" id="table-view-{{ bundle.getName()}}-{{metadata.getName()}}">
        {% for fieldName in metadata.getFieldNames() -%}
            <tr>
            <th>{{ fieldName }}</th>
            <td>{{ "{{" ~ metadata.getName() ~ "." ~ fieldName ~ "}}" }}</td>
        </tr>
    {% endfor %}
</table>
{{ "{% endblock %}" }}
````

#####Cycle 8.4. Run tests (pass)

#####Cycle 8.5. Refactor code

We created a significant technical debt with the previous test.

First, `createTestBundleMock` and `createTestMetadataMock` in `Emag\GeneratorBundle\Tests\Generator\TemplateGeneratorTest` duplicates the same methods in `Emag\GeneratorBundle\Tests\Generator\RouteGeneratorTest`. Move those methods to a new abstract class `Emag\GeneratorBundle\Tests\AbstractTestCase` and change their visibility to `protected` so they are visible to sub-classes. Make `Emag\GeneratorBundle\Tests\Generator\TemplateGeneratorTest` and `Emag\GeneratorBundle\Tests\Generator\RouteGeneratorTest` extend from `Emag\GeneratorBundle\Tests\AbstractTestCase`

Second, we put the expected template as an inline string. To make the test cleaner, let's move the expected template to a file.

- Create **Tests/Expected/Template/view.html.twig**

````html
{% extends 'base.html.twig' %}
{% block body %}
    <table class="table-view" id="table-view-TestBundle-TestEntity">
        <tr>
            <th>testField</th>
            <td>{{TestEntity.testField}}</td>
        </tr>
    </table>
{% endblock %}
````

Update the test in **Tests/Generator/TemplateGeneratorTest.php**

````php
public function testGenerateViewTemplate()
{
    $twig = new \Twig_Environment(new \Twig_Loader_Filesystem(array(__DIR__ . '/../../Templates')));
    $templateGenerator = new \Emag\GeneratorBundle\Generator\TemplateGenerator($twig);

    $metadataMock = $this->createTestMetadataMock();

    $metadataMock->expects($this->any())
            ->method('getFieldNames')
            ->will($this->returnValue(array('testField')));

    $bundleMock = $this->createTestBundleMock();

    $template = $templateGenerator->getTemplate($bundleMock, $metadataMock, 'view');

    $filename = sprintf('%s%2$s..%2$sExpected%2$sTemplate%2$sview.html.twig', __DIR__, DIRECTORY_SEPARATOR);
    $expectedTemplate = file_get_contents($filename);
    $this->assertEquals($expectedTemplate, $template);
}
````

###4.3.2.9 Generate template for edit action

Given an entity called **TestEntity** within a bundle **TestBundle**. The generated twig template for the **edit** action should look like:  

````html
{% extends 'base.html.twig' %}
{% block body -%}
    <h1>TestEntity</h1>
    {{ form(edit_form) }}
{% endblock %}
````

#####Cycle 9.1. Add a test

- Create **Tests/Expected/Template/edit.html.twig**
````html
{% extends 'base.html.twig' %}
{% block body -%}
    <h1>TestEntity</h1>
    {{ form(edit_form) }}
{% endblock %}
````

Add the following test to `Tests/Generator/TemplateGeneratorTest.php`

````php
public function testGenerateEditTemplate()
{
    $twig = new \Twig_Environment(new \Twig_Loader_Filesystem(array(__DIR__ . '/../../Templates')));
    $templateGenerator = new \Emag\GeneratorBundle\Generator\TemplateGenerator($twig);

    $metadataMock = $this->createTestMetadataMock();

    $bundleMock = $this->createTestBundleMock();

    $template = $templateGenerator->getTemplate($bundleMock, $metadataMock, 'edit');

    $filename = sprintf('%s%2$s..%2$sExpected%2$sTemplate%2$sedit.html.twig', __DIR__, DIRECTORY_SEPARATOR);
    $expectedTemplate = file_get_contents($filename);
    $this->assertEquals($expectedTemplate, $template);
}
````
#####Cycle 9.2. Run all tests and see if the new one fails (it does)
#####Cycle 9.3. Write some code
#####Cycle 9.4. Run tests (pass)
#####Cycle 9.5. Refactor code

#####Cycle 10.1. Add a test
#####Cycle 10.2. Run all tests and see if the new one fails (it does)
#####Cycle 10.3. Write some code
#####Cycle 10.4. Run tests (pass)
#####Cycle 10.5. Refactor code


#####Cycle 11.1. Add a test
#####Cycle 11.2. Run all tests and see if the new one fails (it does)
#####Cycle 11.3. Write some code
#####Cycle 11.4. Run tests (pass)
#####Cycle 11.5. Refactor code


#####Cycle 12.1. Add a test
#####Cycle 12.2. Run all tests and see if the new one fails (it does)
#####Cycle 12.3. Write some code
#####Cycle 12.4. Run tests (pass)
#####Cycle 12.5. Refactor code

#####Cycle 13.1. Add a test
#####Cycle 13.2. Run all tests and see if the new one fails (it does)
#####Cycle 13.3. Write some code
#####Cycle 13.4. Run tests (pass)
#####Cycle 13.5. Refactor code
