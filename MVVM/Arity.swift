//
// Created by Brandon Kase on 5/6/16.
// Copyright (c) 2016 Math Camp. All rights reserved.
//

//HACK CITY, HACK HACK CITY
typealias Arity = Int
func arity<R>(f: () -> R) -> Arity {
  return 0
}
func arity<A,R>(f: A -> R) -> Arity {
  return 1
}
func arity<A,B,R>(f: (A, B) -> R) -> Arity {
  return 2
}
func arity<A,B,C,R>(f: (A, B, C) -> R) -> Arity {
  return 3
}
func arity<A,B,C,D,R>(f: (A, B, C, D) -> R) -> Arity {
  return 4
}
func arity<A,B,C,D,E,R>(f: (A, B, C, D, E) -> R) -> Arity {
  return 5
}
func arity<A,B,C,D,E,F,R>(f: (A, B, C, D, E, F) -> R) -> Arity {
  return 6
}
func arity<A,B,C,D,E,F,G,R>(f: (A, B, C, D, E, F, G) -> R) -> Arity {
  return 7
}
func arity<A,B,C,D,E,F,G,H,R>(f: (A, B, C, D, E, F, G, H) -> R) -> Arity {
  return 8
}
func arity<A,B,C,D,E,F,G,H,I,R>(f: (A, B, C, D, E, F, G, H, I) -> R) -> Arity {
  return 9
}
func arity<A,B,C,D,E,F,G,H,I,J,R>(f: (A, B, C, D, E, F, G, H, I, J) -> R) -> Arity {
  return 10
}
func arity<A,B,C,D,E,F,G,H,I,J,K,R>(f: (A, B, C, D, E, F, G, H, I, J, K) -> R) -> Arity {
  return 11
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L) -> R) -> Arity {
  return 12
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M) -> R) -> Arity {
  return 13
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,N,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M, N) -> R) -> Arity {
  return 14
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O) -> R) -> Arity {
  return 15
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P) -> R) -> Arity {
  return 16
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q) -> R) -> Arity {
  return 17
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,Z,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, Z) -> R) -> Arity {
  return 18
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,Z,Y,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, Z, Y) -> R) -> Arity {
  return 19
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,Z,Y,X,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, Z, Y, X) -> R) -> Arity {
  return 20
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,Z,Y,X,W,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, Z, Y, X, W) -> R) -> Arity {
  return 20
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,Z,Y,X,W,V,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, Z, Y, X, W, V) -> R) -> Arity {
  return 21
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,Z,Y,X,W,V,U,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, Z, Y, X, W, V, U) -> R) -> Arity {
  return 22
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,Z,Y,X,W,V,U,T,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, Z, Y, X, W, V, U, T) -> R) -> Arity {
  return 23
}
func arity<A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,Z,Y,X,W,V,U,T,S,R>(f: (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, Z, Y, X, W, V, U, T, S) -> R) -> Arity {
  return 24
}
