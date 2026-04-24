# stylesync_dataconnect_sdk SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
OutfitPlanner7485eConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetUserById
#### Required Arguments
```dart
String id = ...;
OutfitPlanner7485eConnector.instance.getUserById(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetUserByIdData, GetUserByIdVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await OutfitPlanner7485eConnector.instance.getUserById(
  id: id,
);
GetUserByIdData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = OutfitPlanner7485eConnector.instance.getUserById(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetClothingItemsByUser
#### Required Arguments
```dart
String ownerId = ...;
OutfitPlanner7485eConnector.instance.getClothingItemsByUser(
  ownerId: ownerId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetClothingItemsByUserData, GetClothingItemsByUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await OutfitPlanner7485eConnector.instance.getClothingItemsByUser(
  ownerId: ownerId,
);
GetClothingItemsByUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String ownerId = ...;

final ref = OutfitPlanner7485eConnector.instance.getClothingItemsByUser(
  ownerId: ownerId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetOutfitsByUser
#### Required Arguments
```dart
String ownerId = ...;
OutfitPlanner7485eConnector.instance.getOutfitsByUser(
  ownerId: ownerId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetOutfitsByUserData, GetOutfitsByUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await OutfitPlanner7485eConnector.instance.getOutfitsByUser(
  ownerId: ownerId,
);
GetOutfitsByUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String ownerId = ...;

final ref = OutfitPlanner7485eConnector.instance.getOutfitsByUser(
  ownerId: ownerId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetAllCategoriesWithTypes
#### Required Arguments
```dart
// No required arguments
OutfitPlanner7485eConnector.instance.getAllCategoriesWithTypes().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAllCategoriesWithTypesData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await OutfitPlanner7485eConnector.instance.getAllCategoriesWithTypes();
GetAllCategoriesWithTypesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = OutfitPlanner7485eConnector.instance.getAllCategoriesWithTypes().ref();
ref.execute();

ref.subscribe(...);
```


### GetAllColors
#### Required Arguments
```dart
// No required arguments
OutfitPlanner7485eConnector.instance.getAllColors().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAllColorsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await OutfitPlanner7485eConnector.instance.getAllColors();
GetAllColorsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = OutfitPlanner7485eConnector.instance.getAllColors().ref();
ref.execute();

ref.subscribe(...);
```


### GetClothingItemDetail
#### Required Arguments
```dart
String id = ...;
OutfitPlanner7485eConnector.instance.getClothingItemDetail(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetClothingItemDetailData, GetClothingItemDetailVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await OutfitPlanner7485eConnector.instance.getClothingItemDetail(
  id: id,
);
GetClothingItemDetailData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = OutfitPlanner7485eConnector.instance.getClothingItemDetail(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateUser
#### Required Arguments
```dart
String email = ...;
String username = ...;
String firstName = ...;
String lastName = ...;
OutfitPlanner7485eConnector.instance.createUser(
  email: email,
  username: username,
  firstName: firstName,
  lastName: lastName,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateUserData, CreateUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await OutfitPlanner7485eConnector.instance.createUser(
  email: email,
  username: username,
  firstName: firstName,
  lastName: lastName,
);
CreateUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String email = ...;
String username = ...;
String firstName = ...;
String lastName = ...;

final ref = OutfitPlanner7485eConnector.instance.createUser(
  email: email,
  username: username,
  firstName: firstName,
  lastName: lastName,
).ref();
ref.execute();
```


### CreateCategory
#### Required Arguments
```dart
String name = ...;
OutfitPlanner7485eConnector.instance.createCategory(
  name: name,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateCategoryData, CreateCategoryVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await OutfitPlanner7485eConnector.instance.createCategory(
  name: name,
);
CreateCategoryData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String name = ...;

final ref = OutfitPlanner7485eConnector.instance.createCategory(
  name: name,
).ref();
ref.execute();
```


### CreateClothingType
#### Required Arguments
```dart
String name = ...;
String categoryId = ...;
OutfitPlanner7485eConnector.instance.createClothingType(
  name: name,
  categoryId: categoryId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateClothingTypeData, CreateClothingTypeVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await OutfitPlanner7485eConnector.instance.createClothingType(
  name: name,
  categoryId: categoryId,
);
CreateClothingTypeData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String name = ...;
String categoryId = ...;

final ref = OutfitPlanner7485eConnector.instance.createClothingType(
  name: name,
  categoryId: categoryId,
).ref();
ref.execute();
```


### CreateClothingItem
#### Required Arguments
```dart
String ownerId = ...;
String imageUrl = ...;
String categoryId = ...;
String clothingTypeId = ...;
OutfitPlanner7485eConnector.instance.createClothingItem(
  ownerId: ownerId,
  imageUrl: imageUrl,
  categoryId: categoryId,
  clothingTypeId: clothingTypeId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateClothingItem, we created `CreateClothingItemBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateClothingItemVariablesBuilder {
  ...
   CreateClothingItemVariablesBuilder name(String? t) {
   _name.value = t;
   return this;
  }

  ...
}
OutfitPlanner7485eConnector.instance.createClothingItem(
  ownerId: ownerId,
  imageUrl: imageUrl,
  categoryId: categoryId,
  clothingTypeId: clothingTypeId,
)
.name(name)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateClothingItemData, CreateClothingItemVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await OutfitPlanner7485eConnector.instance.createClothingItem(
  ownerId: ownerId,
  imageUrl: imageUrl,
  categoryId: categoryId,
  clothingTypeId: clothingTypeId,
);
CreateClothingItemData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String ownerId = ...;
String imageUrl = ...;
String categoryId = ...;
String clothingTypeId = ...;

final ref = OutfitPlanner7485eConnector.instance.createClothingItem(
  ownerId: ownerId,
  imageUrl: imageUrl,
  categoryId: categoryId,
  clothingTypeId: clothingTypeId,
).ref();
ref.execute();
```


### AddColorToClothingItem
#### Required Arguments
```dart
String clothingItemId = ...;
String colorId = ...;
OutfitPlanner7485eConnector.instance.addColorToClothingItem(
  clothingItemId: clothingItemId,
  colorId: colorId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<AddColorToClothingItemData, AddColorToClothingItemVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await OutfitPlanner7485eConnector.instance.addColorToClothingItem(
  clothingItemId: clothingItemId,
  colorId: colorId,
);
AddColorToClothingItemData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String clothingItemId = ...;
String colorId = ...;

final ref = OutfitPlanner7485eConnector.instance.addColorToClothingItem(
  clothingItemId: clothingItemId,
  colorId: colorId,
).ref();
ref.execute();
```


### AddOccasionToClothingItem
#### Required Arguments
```dart
String clothingItemId = ...;
String occasionId = ...;
OutfitPlanner7485eConnector.instance.addOccasionToClothingItem(
  clothingItemId: clothingItemId,
  occasionId: occasionId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<AddOccasionToClothingItemData, AddOccasionToClothingItemVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await OutfitPlanner7485eConnector.instance.addOccasionToClothingItem(
  clothingItemId: clothingItemId,
  occasionId: occasionId,
);
AddOccasionToClothingItemData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String clothingItemId = ...;
String occasionId = ...;

final ref = OutfitPlanner7485eConnector.instance.addOccasionToClothingItem(
  clothingItemId: clothingItemId,
  occasionId: occasionId,
).ref();
ref.execute();
```


### CreateOutfit
#### Required Arguments
```dart
String ownerId = ...;
OutfitPlanner7485eConnector.instance.createOutfit(
  ownerId: ownerId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateOutfit, we created `CreateOutfitBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateOutfitVariablesBuilder {
  ...
   CreateOutfitVariablesBuilder name(String? t) {
   _name.value = t;
   return this;
  }
  CreateOutfitVariablesBuilder topId(String? t) {
   _topId.value = t;
   return this;
  }
  CreateOutfitVariablesBuilder bottomId(String? t) {
   _bottomId.value = t;
   return this;
  }
  CreateOutfitVariablesBuilder shoeId(String? t) {
   _shoeId.value = t;
   return this;
  }

  ...
}
OutfitPlanner7485eConnector.instance.createOutfit(
  ownerId: ownerId,
)
.name(name)
.topId(topId)
.bottomId(bottomId)
.shoeId(shoeId)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateOutfitData, CreateOutfitVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await OutfitPlanner7485eConnector.instance.createOutfit(
  ownerId: ownerId,
);
CreateOutfitData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String ownerId = ...;

final ref = OutfitPlanner7485eConnector.instance.createOutfit(
  ownerId: ownerId,
).ref();
ref.execute();
```


### DeleteClothingItem
#### Required Arguments
```dart
String id = ...;
OutfitPlanner7485eConnector.instance.deleteClothingItem(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteClothingItemData, DeleteClothingItemVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await OutfitPlanner7485eConnector.instance.deleteClothingItem(
  id: id,
);
DeleteClothingItemData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = OutfitPlanner7485eConnector.instance.deleteClothingItem(
  id: id,
).ref();
ref.execute();
```

