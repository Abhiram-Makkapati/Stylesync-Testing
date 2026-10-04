# StyleSync White-Box Executable Test Suite

The suite uses the project's existing `flutter_test` runner. Firebase-backed services now accept optional injected Firebase instances; production calls still default to the same `FirebaseAuth.instance` / `FirebaseFirestore.instance` objects, so application behavior is unchanged. Tests use in-memory Firebase fakes.

## Run

```bash
flutter pub get
flutter test
flutter test --coverage
```

Coverage output is written to `coverage/lcov.info` by the last command.

## `test/clothing_item_test.dart`

1. **toFirestore maps every field and converts createdAt to Timestamp** — covers the normal serialization path, every mapped field, timestamp conversion, and confirms the document ID is not stored as data.
2. **toFirestore converts null tags to an empty list** — covers the `tags ?? []` fallback branch.
3. **fromFirestore maps dynamic lists to strings and preserves id** — covers normal deserialization plus `.map((e) => e.toString())` for `specificStyles`, `colors`, `occasions`, and `tags`.
4. **fromFirestore applies defaults for omitted optional/defaulted fields** — covers all `??` defaults for category, item type, style, colors, occasions, image URL, and `DateTime.now()`.
5. **fromFirestore throws StateError when document has no data** — covers the explicit `data == null` error branch.
6. **fromSnapshot delegates to fromFirestore** — covers the backwards-compatible factory.

## `test/closet_service_test.dart`

7. **addClothingItem creates a document under current user** — covers authenticated CREATE and UID-scoped Firestore path construction.
8. **getUserClothingItems returns newest first** — covers authenticated READ, document mapping, and `createdAt desc` ordering.
9. **getUserClothingItems returns empty list for empty closet** — covers empty-query behavior.
10. **updateClothingItem overwrites fields on existing document** — covers authenticated UPDATE.
11. **updateClothingItem on missing document throws** — covers an invalid-ID/error path from `.update()`.
12. **updateItemTags supports empty and duplicate tag values exactly as passed** — covers tags-only UPDATE and edge inputs the current implementation does not validate/deduplicate.
13. **deleteClothingItem removes existing document** — covers authenticated DELETE.
14. **matches exact, plural/singular, contains, reverse-contains, and excludes empty/nonmatch** — covers the major branches inside `getItemsByCategory`: empty stored category, exact match, stored plural, contains/reverse-contains, and final false branch.
15. **requested plural matches singular stored category** — specifically covers the `lower.endsWith('s')` singular/plural branch.
16. **empty requested category follows current contains-empty behavior** — covers the real edge behavior caused by Dart `String.contains('')`.
17. **query returns only category+occasion matches in descending date order** — covers the one-time compound Firestore query and ordering.
18. **watch query emits matching data and updates after a new matching document** — covers the live-query stream mapping path.
19. **all public CRUD/query methods reject or return sync error when user is absent** — covers the `userId == null` guard in each ClosetService public method.

## `test/auth_service_test.dart`

20. **signIn returns user, trims email, and stores rememberMe=true** — covers normal login, email trimming, user extraction, and remembered-login SharedPreferences branch.
21. **signIn stores rememberMe=false** — covers the opposite preference branch.
22. **signIn propagates FirebaseAuthException** — covers Firebase authentication failure.
23. **signUp trims email and returns created user** — covers normal signup and trim behavior.
24. **signUp propagates Firebase auth errors** — covers signup exception propagation.
25. **signOut keeps preferences when rememberMe is true** — covers the `remember == true` path where preferences are retained.
26. **signOut clears preferences when rememberMe is false or missing** — covers both explicit false and `?? false` default branches.
27. **handleAutoLogout leaves remembered user signed in** — covers the no-sign-out branch.
28. **handleAutoLogout signs out when rememberMe false/missing** — covers automatic sign-out.

## `test/registration_form_test.dart`

29. **empty submission covers all required-field validation branches** — covers first name, last name, username, email, password, and confirmation empty validators.
30. **invalid boundary values cover short username, invalid email, short password, mismatch** — covers username `< 3`, regex failure, password `< 8`, and mismatched confirmation.
31. **duplicate username is case-insensitive** — covers `UserData.isUsernameTaken()` through the real registration validator.
32. **valid boundary values invoke onRegister with entered values** — covers the valid form branch and exact minimum boundaries (3-char username, 8-char password).
33. **password fields toggle obscureText and non-password field has no visibility icon** — covers password visibility state change in `CustomTextField`.

## `test/user_data_test.dart`

34. **username helpers are case-insensitive, reject duplicate, clear state, and notify only on changes** — covers true/false `isUsernameTaken`, `addUsername` insert vs duplicate branch, `notifyListeners`, and `clearAllData`.
35. **populateUsernames lowercases non-null usernames and ignores missing username** — covers `username != null` true/false branches.
36. **saveOutfit writes date and ids for authenticated user** — covers authenticated planned-outfit CREATE.
37. **saveOutfit throws when unauthenticated** — covers the explicit authentication exception.
38. **savePendingProfile writes explicit createdAt and merges existing fields** — covers explicit timestamp and `SetOptions(merge: true)` behavior.
39. **savePendingProfile supplies current time when createdAt is null** — covers `createdAt ?? DateTime.now()`.

## `test/outfit_service_test.dart`

40. **saveOutfit stores current uid and all item ids** — covers authenticated `/outfits` CREATE and server timestamp field.
41. **saveOutfit accepts empty ids because implementation has no validation** — covers an actual boundary behavior without inventing validation.
42. **saveOutfit throws when unauthenticated** — covers the authentication guard.
43. **getUserOutfits returns empty immediately when unauthenticated** — covers the method's distinct unauthenticated READ behavior (`return []`).
44. **getUserOutfits filters by uid, sorts descending, and includes document id** — covers query filtering, ordering, map spread, and generated output `id`.

## `test/support_services_test.dart`

45. **missing tutorial preference defaults to false and markTutorialAsSeen writes true** — covers `?? false` and persistence write.
46. **stored false remains false** — covers an explicitly stored false preference.
47. **FilterBroadcastService publishes exact category/filter payload to listeners** — covers broadcast stream publication and payload structure.
48. **saveSettings creates data and merge preserves unrelated existing field** — covers SuggestionLimiter Firestore write and merge behavior.
49. **loadSettings returns null for missing document** — covers missing settings data.
50. **saveSettings accepts empty map and preserves document** — covers the empty-map boundary supported by the current method signature.

## Production changes made only for testability

The following classes received optional constructor injection while keeping their original singleton defaults:

- `AuthService`
- `ClosetService`
- `OutfitService`
- `core/models/UserData`
- `SuggestionLimiterService`

`AuthService.handleAutoLogout` also accepts an optional `FirebaseAuth` instance. Existing application calls require no changes.
