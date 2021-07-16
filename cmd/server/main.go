package main

import (
	"fmt"
	"net/http"
	"os"
	"sync"

	"github.com/gorilla/handlers"
)

func main() {
	mux := http.NewServeMux()

	newHandler := func(rw http.ResponseWriter, r *http.Request) {
		rw.Write([]byte("hello world!"))
	}

	mux.HandleFunc("/hello", newHandler)
	fs := http.FileServer(http.Dir("./static"))
	mux.Handle("/", fs)

	wrap := handlers.LoggingHandler(os.Stdout, mux)

	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		err := http.ListenAndServe(":3030", wrap)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		wg.Done()
	}()

	fmt.Println("vim-go")
	wg.Wait()
}
