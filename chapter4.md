#<center>4. TDD & Vendor Bundle</center>

<br/>

##4.1 Before we start

###4.1.1 TDD

TDD stands for Test Driven Development. The basic idea is very simple: write tests before writing production code.

A complete test-driven development cycle consists on the following sequence

1. Add a test
2. Run all tests and see if the new one fails
3. Write some code
4. Run tests
5. Refactor code
6. Repeat

We are not going to study TDD in depth here. There is plenty of material about the subject, you can start by the [wikipedia](https://en.wikipedia.org/wiki/Test-driven_development) page about TDD. The process may seem awkward and counter-intuitive at first. But once you get used to it, you will start seeing the benefits it will bring to your code quality, and to your productivity.

###4.1.2 Symfony best practices for reusable bundles

After our previous experience with Sensio Generator Bundle, you may have noticed that is not the best neither the most flexible code generator ever. In this chapter we will attempt to come with a better alternative to that bundle. The main motivation for developing a vendor bundle is code re-usability. Therefore, one of the most expected aspects is a well decoupled and extensible code.

 Before we start, let's highlight some of the Symfony best practices for reusable bundles.

> - A bundle should come with a test suite written with PHPUnit and stored under the Tests/ directory.
- The tests should cover at least 95% of the code base.
- All classes and functions must come with full PHPDoc.
- Extensive documentation should also be provided.

I developed my own flavor of good practices also, that I would like to share with you
> - The tests should cover <strike>at least 95%</strike> **100%** of the code base.
- Avoid dependencies, and when necessary keep them to the minimum, with maximum compatibility.
- When requesting configurations from the user, set default values whenever you can.

##4.2 Generators

###4.2.1 View action generator

Many programmers may have experienced the blanc page effect. Is when you are about to start something from scratch and you don't find exactly from where to start. One of my ways to get out of this situation is to start with the most obvious and straight forward tasks. We will assume that our bundle will be distributed by **composer** and maintained using **git**.
- Create a new directory somewhere in your working directory but not within the application's directory.
- Create **composer.json**

````json
{
    "name": "emag/generator-bundle",
    "description": "Emag code generator",
    "type": "symfony-bundle",
    "license": "MIT",
    "require-dev": {
        "symfony/routing": "*",
        "symfony/dependency-injection": "*",
        "symfony/http-kernel": "*",
        "symfony/options-resolver": "*",
        "twig/twig": "*",
        "doctrine/common": "*",
        "doctrine/orm": ">=2.0",
        "phpunit/phpunit": "*"
    },
    "autoload": {
        "psr-4": {
            "Emag\\GeneratorBundle\\": ""
        }
    }
}
````

Run `composer install`. composer will install the required components under the **vendor** directory.

Knowing which components you may need in advance is nice to have, but is not mandatory. It is normal to add components that you need as you go. With experience you will start making better guesses.

- Create **.gitignore** to exclude the vendor directory and composer.lock that will be created by composer

````
vendor
composer.lock
````

One more thing before starting writing code, is to create a configuration file for PHPUnit.

- Create **phpunit.xml.dist**

````xml
<?xml version="1.0" encoding="UTF-8"?>

<phpunit bootstrap="./vendor/autoload.php" colors="true">
    <testsuites>
        <testsuite name="GeneratorBundle">
            <directory suffix="Test.php">./Tests</directory>
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

Let's start with the route generation. Suppose we have an entity called **TestEntity** within a bundle called **TestBundle**. The expected route for the **view** action would have a path like */test/testentity/{id}/view* and a controller action like *TestBundle:TestEntity:view*. To write the first test, all we need to do is to write the previous expectation in PHP.

We will create a **Tests** directory where we will put all the tests.

- Create **Tests/Generator/RouteGeneratorTest.php**

````php
<?php

namespace Emag\GeneratorBundle\Tests\Generator;

class RouteGeneratorTest extends \PHPUnit_Framework_TestCase
{

    public function testGenerateViewRoute()
    {
        $bundle = new \Emag\GeneratorBundle\Tests\Stubs\TestBundle\TestBundle();
        $metadata = new \Doctrine\ORM\Mapping\ClassMetadata('TestEntity');

        $routeGenerator = new \Emag\GeneratorBundle\Generator\RouteGenerator();

        $route = $routeGenerator->getRoute($bundle, $metadata, 'view');

        $this->assertEquals('/test/testentity/{id}/view', $route->getPath());
        $this->assertEquals(
                array('_controller' => 'TestBundle:TestEntity:view'), $route->getDefaults()
        );
        $this->assertContains('GET', $route->getMethods());
    }
}
````

The previous test requires a *fake* test bundle in **Tests/Stubs/TestBundle/TestBundle.php**

````php
<?php

namespace Emag\GeneratorBundle\Tests\Stubs\TestBundle;

use Symfony\Component\HttpKernel\Bundle\BundleInterface;

class TestBundle implements BundleInterface
{

    public function getName()
    {
        return 'TestBundle';
    }

    //And empty body implementations of methods required by BundleInterface
}
````

Running `phpunit` now will show the obvious error  
`PHP Fatal error:  Class 'Emag\GeneratorBundle\Generator\RouteGenerator' not found`

We will create the **RouteGenerator** that will make the test pass.

- Create **Generator/RouteGenerator.php**

````php
<?php

namespace Emag\GeneratorBundle\Generator;

use Doctrine\ORM\Mapping\ClassMetadata;
use Symfony\Component\HttpKernel\Bundle\BundleInterface;
use Symfony\Component\Routing\Route;

class RouteGenerator
{

    /**
     *
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
        $route->setMethods(array('get'));
        $route->setDefaults(array('_controller' => $this->getControllerAction($bundle, $metadata, $action)));
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

Let's test our work
````bash
$ phpunit
PHPUnit 4.8.19 by Sebastian Bergmann and contributors.

Time: 666 ms, Memory: 8.50Mb

OK (1 test, 3 assertions)

Code Coverage Report:

 Summary:
  Classes: 100.00% (1/1)  
  Methods: 100.00% (5/5)  
  Lines:   100.00% (12/12)

\Emag\GeneratorBundle\Generator::RouteGenerator
  Methods: 100.00% ( 5/ 5)   Lines: 100.00% ( 12/ 12)
````

Looks good so far. What if we try to generate a route for an invalid action? We should expect to get an `\InvalidArgumentException`, as we did previously, we will just write this expectation in PHP.

We will edit **Tests/Generator/RouteGeneratorTest.php** and add the following test:
````php
<?
/**
 * @expectedException InvalidArgumentException
 * @expectedExceptionMessage invalid action "invalidAction"
 */
public function testGenerateInvalidActionRoute()
{
    $bundle = new \Emag\GeneratorBundle\Tests\Stubs\TestBundle\TestBundle();
    $metadata = new \Doctrine\ORM\Mapping\ClassMetadata('Entity');
    $routeGenerator = new \Emag\GeneratorBundle\Generator\RouteGenerator();

    $routeGenerator->getRoute($bundle, $metadata, 'invalidAction');
}
````

If you run the test suite again, it will fail.
````bash
There was 1 failure:

1) Emag\GeneratorBundle\Tests\Generator\RouteGeneratorTest::testGenerateInvalidActionRoute
Failed asserting that exception of type "InvalidArgumentException" is thrown.
````

Next, we update **getRoute** method to throw an exception when given an invalid action.
- Edit **Generator/RouteGenerator.php** and update getRoute method

````php
<?
/**
 *
 * @param BundleInterface $bundle
 * @param ClassMetadata $metadata
 * @param string $action
 * @return string
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
            throw new \InvalidArgumentException(sprintf('invalid action "%s"', $action));
    }
    return $route;
}
````

Now the tests pass again. We will continue looping through expectation/test/code and see how things evolve.

**Expectations:** For a given TestEntity having one field **testField**, we expect the view template to look like:
````html
{% extends 'base.html.twig' %}
{% block body %}
    <table>
        <tr>
            <th>testField</th>
            <td>{{TestEntity.testField}}</td>
        </tr>
    </table>
{% endblock %}
````
The class that will generate the views will use a `Twig_Environment` and render Twig templates of Twig templates.

**Test:**

- Create **Tests/Generator/TemplateGeneratorTest.php**

````php
<?php

namespace Emag\GeneratorBundle\Tests\Generator;

class TemplateGeneratorTest extends \PHPUnit_Framework_TestCase
{

    public function testGenerateViewTemplate()
    {
        $metadata = new \Doctrine\ORM\Mapping\ClassMetadata('TestEntity');
        $metadata->mapField(array(
            'fieldName' => 'testField',
        ));

        $twig = new \Twig_Environment(new \Twig_Loader_Filesystem(array(__DIR__. '/../../Templates')));

        $templateGenerator = new \Emag\GeneratorBundle\Generator\TemplateGenerator($twig);

        $template = $templateGenerator->getTemplate($metadata, 'view');
        $expectedTemplate = <<<EOF
{% extends 'base.html.twig' %}
{% block body %}
    <table>
        <tr>
            <th>testField</th>
            <td>{{TestEntity.testField}}</td>
        </tr>
    </table>
{% endblock %}
EOF;
        $this->assertEquals($expectedTemplate, $template);
    }

}
````

**Code:**
- Create **Generator/TemplateGenerator.php**

````php
<?php

namespace Emag\GeneratorBundle\Generator;

use Doctrine\ORM\Mapping\ClassMetadata;

class TemplateGenerator
{

    /**
     *
     * @var \Twig_Environment
     */
    private $twig;

    /**
     *
     * @param \Twig_Environment $twig
     */
    public function __construct(\Twig_Environment $twig)
    {
        $this->twig = $twig;
    }

    /**
     *
     * @param ClassMetadata $metadata
     * @param string $action
     * @return string
     * @throws \InvalidArgumentException
     */
    public function getTemplate(ClassMetadata $metadata, $action)
    {
        $template = null;
        switch ($action) {
            case 'view':
                $template = $this->createViewTemplate($metadata, $action);
                break;
            default:
                throw new \InvalidArgumentException(sprintf('invalid action "%s"', $action));
        }
        return $template;
    }

    /**
     *
     * @param ClassMetadata $metadata
     * @param string $action
     * @return string
     */
    protected function createViewTemplate(ClassMetadata $metadata, $action)
    {
        return $this->twig->render($this->getTemplateName($action), array('metadata' => $metadata));
    }

    /**
     *
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
    <table>
        {% for fieldName in metadata.getFieldNames() -%}
            <tr>
            <th>{{ fieldName }}</th>
            <td>{{ "{{" ~ metadata.getName() ~ "." ~ fieldName ~ "}}" }}</td>
        </tr>
    {% endfor %}
</table>
{{ "{% endblock %}" }}
````

Running the tests again, we notice that the code coverage has dropped to 88.89%. Indeed, we forgot to test generating a template for an invalid action. Let's edit **Tests/Generator/TemplateGeneratorTest.php** and add the required test.

````php
<?
/**
 * @expectedException InvalidArgumentException
 * @expectedExceptionMessage invalid action "invalidAction"
 */
public function testGenerateInvalidTemplate()
{
    $metadata = new \Doctrine\ORM\Mapping\ClassMetadata('TestEntity');

    $twig = new \Twig_Environment(new \Twig_Loader_Filesystem(array(__DIR__. '/../../Templates')));

    $templateGenerator = new \Emag\GeneratorBundle\Generator\TemplateGenerator($twig);

    $templateGenerator->getTemplate($metadata, 'invalidAction');
}
````

Looks better now, well, almost. Don't omit the 5th step of TDD sequence **refactor code**. We have already created some technical debt that we must clean up before proceeding.

TemplateGeneratorTest::testGenerateViewTemplate() compares the generated template to a hard-coded expected template. We can easily foresee that this file may end up with more twig strings than PHP code.
We will store the expected template in a file and compare it's content to the generated template.

- Create **Tests/Expected/views/test-view.html.twig**
````html
{% extends 'base.html.twig' %}
{% block body %}
    <table>
        <tr>
            <th>testField</th>
            <td>{{TestEntity.testField}}</td>
        </tr>
    </table>
{% endblock %}
````

Update TemplateGeneratorTest::testGenerateViewTemplate() to assign `file_get_contents('../Expected/views/test-view.html.twig')` to `$expectedTemplate` instead of the hard-coded string. Running the tests again confirms that we didn't broke anything.

>**Why refactor testing code anyway?**  
Maintaining the quality of testing code is equally important to maintaining the quality of production code. Otherwise, the tests will be harder and harder to update and add new ones. Then they will start to fail. You will eventually put some effort and fix them. Then they will fail again, then no one will run them again and they will become useless. Don't forget also that a good test suite is your strongest asset to refactor production code with confidence.  
Changing production code is tightrope walking, unit tests are your safety net.

Both tests in TemplateGeneratorTest created a TemplateGenerator object. Most probably, many other tests will need the same object. We can declare a class member of that object and initialized before the tests run. Then remove the instantiation of `$twig` and `$templateGenerator` from the tests and use `$this->templateGenerator` instead. The final result looks like

````php
<?php

namespace Emag\GeneratorBundle\Tests\Generator;

use Doctrine\ORM\Mapping\ClassMetadata;
use Emag\GeneratorBundle\Generator\TemplateGenerator;

class TemplateGeneratorTest extends \PHPUnit_Framework_TestCase
{

    /**
     *
     * @var TemplateGenerator
     */
    private $templateGenerator;

    protected function setUp()
    {
        $twig = new \Twig_Environment(new \Twig_Loader_Filesystem(array(__DIR__ . '/../../Templates')));
        $this->templateGenerator = new TemplateGenerator($twig);
    }

    public function testGenerateViewTemplate()
    {
        $metadata = new ClassMetadata('TestEntity');
        $metadata->mapField(array(
            'fieldName' => 'testField',
        ));

        $template = $this->templateGenerator->getTemplate($metadata, 'view');
        $this->assertEquals(file_get_contents(__DIR__ . '/../Expected/views/test-view.html.twig'), $template);
    }

    /**
     * @expectedException \InvalidArgumentException
     * @expectedExceptionMessage invalid action "invalidAction"
     */
    public function testGenerateInvalidTemplate()
    {
        $metadata = new ClassMetadata('TestEntity');
        $this->templateGenerator->getTemplate($metadata, 'invalidAction');
    }
}
````

Doing well so far. Next, we will expect how a controller action should be.

- Create **Tests/Expected/controllers/TestViewController.php**

````php
<?php

namespace TestBundle\Controller;

class TestEntityController extends \Symfony\Component\HttpKernel\Controller
{

    public function viewAction($id)
    {
        $testEntity = $this->getTestEntity($id);
        $arguments = array('testEntity' => $testEntity);
        return $this->render('TestBundle:testEntity:view.html.twig', $arguments);
    }

    private function getTestEntity($id)
    {
        $entityManager = $this->getDoctrine()->getManager();
        return $entityManager->getRepository('TestBundle:TestEntity')->find($id);
    }
}
````

- Create **Tests/Expected/controllers/TestViewController.php**

````php
<?php

namespace Emag\GeneratorBundle\Tests\Stubs\TestBundle\TestBundle\Controller;

class TestEntityController extends \Symfony\Component\HttpKernel\Controller
{

    public function viewAction($id)
    {
        $testEntity = $this->getTestEntity($id);
        $arguments = array('testEntity' => $testEntity);
        return $this->render('TestBundle:testEntity:view.html.twig', $arguments);
    }

    private function getTestEntity($id)
    {
        $entityManager = $this->getDoctrine()->getManager();
        return $entityManager->getRepository('TestBundle:TestEntity')->find($id);
    }

}
````

- Create **Tests/Generator/ControllerGeneratorTest.php**

````php
<?php

namespace Emag\GeneratorBundle\Tests\Generator;

use Doctrine\ORM\Mapping\ClassMetadata;
use Emag\GeneratorBundle\Tests\Stubs\TestBundle\TestBundle;

class ControllerGeneratorTest extends \PHPUnit_Framework_TestCase
{

    public function testGenerateViewController()
    {
        $bundle = new TestBundle();
        $metadata = new ClassMetadata('TestEntity');
        $twig = new \Twig_Environment(new \Twig_Loader_Filesystem(array(__DIR__ . '/../../Templates')));
        $controllerGenerator = new \Emag\GeneratorBundle\Generator\ControllerGenerator($twig);

        $controller = $controllerGenerator->getController($bundle, $metadata, array('view'));
        $expected = file_get_contents(__DIR__ . '/../Expected/controllers/TestViewController.php');
        $this->assertEquals($this->cleanCode($expected), $this->cleanCode($controller));
    }

    private function cleanCode($code)
    {
        return preg_replace('/ +/', ' ', str_replace("\n", '', $code));
    }
}
````

- Create **Generator/ControllerGenerator.php**
````php
<?php

namespace Emag\GeneratorBundle\Generator;

use Doctrine\ORM\Mapping\ClassMetadata;
use Symfony\Component\HttpKernel\Bundle\BundleInterface;

class ControllerGenerator
{

    /**
     *
     * @var \Twig_Environment
     */
    private $twig;

    /**
     *
     * @param \Twig_Environment $twig
     */
    public function __construct(\Twig_Environment $twig)
    {
        $this->twig = $twig;
    }

    public function getController(BundleInterface $bundle, ClassMetadata $metadata, array $actions)
    {
        return $this->twig->render(
            'controller/controller.html.twig.twig',
            array(
                'actions' => $actions,
                'bundle' => $bundle,
                'lowerEntityName' => lcfirst($metadata->getName()),
                'metadata' => $metadata
            )
        );
    }
}
````

- Create **Templates/controller/controller.html.twig.twig**
````html
{% set entityName = metadata.getName() %}
<?php

namespace {{bundle.getNamespace()}}\Controller;

class {{entityName}}Controller extends \Symfony\Component\HttpKernel\Controller
{

    {% if 'view' in actions -%}
        {% block viewAction %}
        public function viewAction($id)
        {
            ${{lowerEntityName}} = $this->get{{entityName}}($id);
            $arguments = array('{{lowerEntityName}}' => ${{lowerEntityName}});
            return $this->render('TestBundle:{{lowerEntityName}}:view.html.twig', $arguments);
        }
        {% endblock %}
    {% endif %}

    {%- block get -%}
    private function get{{entityName}}($id)
    {
        $entityManager = $this->getDoctrine()->getManager();
        return $entityManager->getRepository('{{bundle.getName()}}:{{entityName}}')->find($id);
    }  
    {%- endblock %}
}
````
