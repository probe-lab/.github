// Command fixture is a tiny program that the CI of this repo builds and tests
// with the shared workflows.
package main

import "fmt"

func main() {
	fmt.Println(greeting("ProbeLab"))
}

func greeting(name string) string {
	return "Hello, " + name
}
