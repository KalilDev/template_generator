/*int A(int m, int n) => m == 0
    ? n + 1
    : n == 0
        ? A(m - 1, 1)
        : A(m - 1, A(m, n - 1));*/

BigInt A(int a, int b) => Ackermann(BigInt.from(a), BigInt.from(b));
//int A(int a, int b) => ackermann(a, b);

main() {
  for (var m = 0; m <= 10; ++m) {
    for (var n = 0; n <= 10; ++n) {
      DateTime now = DateTime.now();
      print("Ackermann($m, $n) = ${A(m, n)}");
      print(
          "Time taken:${(DateTime.now().microsecond - now.microsecond) / 1000}ms");
    }
  }
}

int ackermann(int m, int n) {
  var stack = new OverflowlessStack<int>();
  stack.Push(m);
  while (!stack.IsEmpty) {
    m = stack.Pop();
    while (true) {
      if (m == 0) {
        n = n + 1;
        break;
      } else if (m == 1) {
        n = n + 2;
        break;
      } else if (m == 2) {
        n = n * 2 + 3;
        break;
      } else if (n == 0) {
        m = m - 1;
        n = 1;
      } else {
        stack.Push(m - 1);
        n = n - 1;
      }
    }
  }
  return n;
}

final BigInt3 = BigInt.from(3);

BigInt Ackermann(BigInt m, BigInt n) {
  var stack = new OverflowlessStack<BigInt>();
  stack.Push(m);
  while (!stack.IsEmpty) {
    m = stack.Pop();
    while (true) {
      if (m == BigInt.zero) {
        n = n + BigInt.one;
        break;
      } else if (m == BigInt.one) {
        n = n + BigInt.two;
        break;
      } else if (m == BigInt.two) {
        n = n * BigInt.two + BigInt3;
        break;
      } else if (n == BigInt.zero) {
        m = m - BigInt.one;
        n = BigInt.one;
      } else {
        stack.Push(m - BigInt.one);
        n = n - BigInt.one;
      }
    }
  }
  return n;
}

class SinglyLinkedNode<T> {
  static const int ArraySize = 2048;
  List<T> _array;
  int _size;
  SinglyLinkedNode<T> Next;
  SinglyLinkedNode() {
    _array = List(ArraySize);
    _size = 0;
  }
  bool get IsEmpty => _size == 0;
  SinglyLinkedNode<T> Push(T item) {
    if (_size == ArraySize - 1) {
      SinglyLinkedNode<T> n = new SinglyLinkedNode<T>();
      n.Next = this;
      n.Push(item);
      return n;
    }
    _array[_size++] = item;
    return this;
  }

  T Pop() {
    return _array[--_size];
  }
}

class OverflowlessStack<T> {
  SinglyLinkedNode<T> _head = new SinglyLinkedNode<T>();

  T Pop() {
    T ret = _head.Pop();
    if (_head.IsEmpty && _head.Next != null) {
      _head = _head.Next;
    }
    return ret;
  }

  void Push(T item) {
    _head = _head.Push(item);
  }

  bool get IsEmpty => _head.Next == null && _head.IsEmpty;
}
