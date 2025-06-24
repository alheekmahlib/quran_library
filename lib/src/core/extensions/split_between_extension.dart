// ignore: unintended_html_in_doc_comment
/// Extension on List<T> that provides a method to split a list into sub-lists based on a condition.
extension SplitBetweenExtension<T> on List<T> {
  /// Splits a list into sub-lists based on a condition between consecutive elements.
  ///
  /// The [condition] function takes two consecutive elements and returns a boolean.
  /// When the condition is true, a new sub-list is started.
  ///
  /// Example:
  /// ```dart
  /// final numbers = [1, 2, 3, 1, 2, 3];
  /// final result = numbers.splitBetween((a, b) => a > b);
  /// // result: [[1, 2, 3], [1, 2, 3]]
  /// ```
  ///
  /// Returns a list of lists, where each sub-list contains elements from the original list.
  List<List<T>> splitBetween(bool Function(T first, T second) condition) {
    if (isEmpty) return []; // If the list is empty, return an empty list.

    List<List<T>> result = []; // Result list that will contain the sub-lists.
    List<T> currentGroup = [
      first
    ]; // Current group starts with the first element.

    for (int i = 1; i < length; i++) {
      if (condition(this[i - 1], this[i])) {
        // If the condition is met, add the current group to the result.
        result.add(currentGroup);
        currentGroup = []; // Start a new group.
      }
      currentGroup.add(this[i]); // Add the current element to the group.
    }

    if (currentGroup.isNotEmpty) {
      result.add(currentGroup); // Add the last group.
    }

    return result;
  }
}
