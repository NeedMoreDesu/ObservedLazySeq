# ObservedLazySeq

[![Version](https://img.shields.io/cocoapods/v/ObservedLazySeq.svg?style=flat)](http://cocoapods.org/pods/ObservedLazySeq)
[![License](https://img.shields.io/cocoapods/l/ObservedLazySeq.svg?style=flat)](http://cocoapods.org/pods/ObservedLazySeq)
[![Platform](https://img.shields.io/cocoapods/p/ObservedLazySeq.svg?style=flat)](http://cocoapods.org/pods/ObservedLazySeq)

This pod focuses on building wrapper for objects that are:

1. Loaded lazily, like batch requests from database
2. Observed and updated
3. May need transformation on the way

## Why using this pod?

It makes your application database-agnostic (since you map database objects into some other non-database objects on the way), but allows you to use lazily-created objects (say, use only those 20 objects that tableView asks, not all 10000 that are in the database), and subscribe to changes (default tableView subscription method is very simple to use).

## Example

Create ObservedLazySeq by observing your database (CoreData supported, Reaml is on the way).

```swift
let managedObjectsObserved = CoreDataObserver<DBObject>.create(entityName: "SomeEntityName", primaryKey: "id", managedObjectContext: context)
```

Then transform it to another structure, linking ObservedLazySeq's together

```swift
let newObserved = observed.map({ (oldObject) -> NewObjectType in
            let newObject = NewObjectType()
            newObject.someField = oldObject.someOtherField
            return newObject
        })
```

Then use it in your ViewController like that:

```swift
    var observed: ObservedLazySeq<YourType>! {
        didSet {
            self.observed.subscribeTableView(tableViewGetter: { [weak self] () -> UITableView? in
                return self?.tableView // we explicitly show that we don't care if tableView is here at this moment, since we take it from `self` directly
            })
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.observed.objs.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.observed.objs[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let yourObject = self.observed.getItemAt(indexPath)
        ...
    }
```

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

ObservedLazySeq is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ObservedLazySeq'
```

## Author

Oleksii Horishnii, oleksii.horishnii@gmail.com

## License

ObservedLazySeq is available under the MIT license. See the LICENSE file for more info.
