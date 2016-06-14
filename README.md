# Unified framework

The main purpose of unified framework – is to take identical code base for different platforms.

It is not crossplatform solution, like *Xamarin* or *Phonegap*.

Instead, unified framework give you identical libraries for all supported platforms.

This libraries includes identical implementation for most tasks, required in most applications.

In addition to libraries, framework contains tools to generate platform specific code, 
based on unified declarations, contained in platform independent JSON file.


## Library

The unified framework libraries includes:

- Dependency – component based, loosely coupled systems.
- Threading – multithreading and async execution.
- Storage – operations with local SQLite database and file storage.
- Cloud – interactions with web-based cloud services.
- Ui – user interface components and layouting.

### Dependency

Unified framework use simple dependency injection concepts:

- Each *component* has pure abstract interface (protocol in swift) and at least one *default* implementation.
- You can use *component* only via its interface (you must not think anything about its implementation).
- Any object, which required other components to work, is a *dependent object*. It must resolve dependencies before any actual work.
- *Dependent object* receive components in form of *dependency resolver* – object, that can return component implementation for required component interface.
- *Dependent object* must transfer received *dependency resolver* to other objects, which also can be dependent objects.
- The key feature of resolving process is a *dependency* – singleton object, used as a key to resolve concrete interface. For each interface, involved in dependency injection, there is an only static instance of *dependency* object, which can be used to resolve dependency for this interface.
- To incorporate components in single *dependency resolver*, you must use *dependency container*, which itself is a *dependency resolver* and in addition contains methods to put components into *dependency container*.

You can interpret *dependency container* as a closed bag with components. When you need some component for known interface, you can get it from this bag. The only way to get component from a bag – is a *dependency* singleton object, used as a ticket (or a key) to receive required component.

##### Summary
Once more:

- *component* – object with useful methods, that can be accessed only via pure abstract interface;
- *dependency* – static singleton object, used in resolving process (used to get component implementation);
- *dependency resolver* – provides component implementations from dependency objects;
- *dependency container* – incorporates many components in one place; *

#### Interface declaration
Any component, that support dependency injection, must declare:

- public interface declaration (protocol in swift);
- static *dependency* object;
- helper methods to resolve dependency (it is not required, but very convenient to use).

swift:
```swift
public protocol HelloWorld {
	func sayHello()
}

let HelloWorldDependency = Dependency<HelloWorld>()

extension DependencyResolver {
	var helloWorld: HelloWorld {
		required(HelloWorldDependency)
	}
	var optionalHelloWorld: HelloWorld? {
		optional(HelloWorldDependency)
	}
}
```
java:
```java
public interface HelloWorld {
	void sayHello();

	public static dependency = new Dependency<HelloWorld>();

	public static HelloWorld required(DependencyResolver dependency) {
		return dependency.required(HelloWorld.dependency);
	}
	public static HelloWorld optional(DependencyResolver dependency) {
		return dependency.optional(HelloWorld.dependency);
	}
}
```
### Default implementation
Each component must have at least one *default* implementation, which includes:

- class, starting with prefix *Default*, that implements component interface;
- helper static method to create default implementation and register it in specified dependency container.

swift:
```swift
public class DefaultHelloWorld: HelloWorld {
	public func sayHello() {
		print("hello world")
	}
}

extension DependencyContainer {
	func createDefaultHelloWorld() {
		register(HelloWorldDependency, DefaultHelloWorld())
	}
}
```
java:
```java
public class DefaultHelloWorld implements HelloWorld{
	@Override
	public void sayHello() {
		System.out.println("hello world");
	}

	public static void create(DependencyContainer container) {
		container.register(HelloWorld.dependency, new DefaultHelloWorld());
	}
}
```

#### Creation
swift:
```swift
let dependency = DefaultDependencyContainer()
dependency.create {
	components in
	components.createDefaultHelloWorld()
}
```
java:
```java
DependencyContainer dependency = new DefaultDependencyContainer();
dependency.create((components) -> {
	DefaultHelloWorld.create(components);
});
```
#### Resolving and usage
swift:
```swift
class UsefulObject: DependentObject {
	
	func usefulMethod() {
		helloWorld.sayHello()
	}

	//MARK: - Dependency

	func resolveDependency(dependency: DependencyResolver) {
		self.dependency = dependency
	}
	private var dependency: DependencyResolver!
	private var helloWorld: HelloWorld {
		return dependency.helloWorld
	}

}

class Main {
	func main() {
		...
		let usefulObject = UsefulObject()
		dependency.resolve(usefulObject)
		usefulObject.usefulMethod()
	}
}
```
java:
```java
class UsefulObject implements DependentObject {
	
	void usefulMethod() {
		helloWorld().sayHello();
	}

	// Dependency

	@Override
	void resolveDependency(DependencyResolver dependency) {
		this.dependency = dependency;
	}
	private DependencyResolver dependency;
	private HelloWorld helloWorld() {
		return HelloWorld.required(dependency);
	}

}

class Main {
	void main() {
		...
		UsefulObject usefulObject = new UsefulObject();
		dependency.resolve(usefulObject);
		usefulObject.usefulMethod();
	}
}
```


### Threading

### Storage

### Cloud

## Unified

### Unified declaration file

### Enified code generator



