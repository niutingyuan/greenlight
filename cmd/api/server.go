package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func (app *application) server() error {
	srv := &http.Server{
		Addr:         fmt.Sprintf("localhost:%d", app.config.port),
		Handler:      app.routes(),
		IdleTimeout:  time.Minute,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		ErrorLog:     slog.NewLogLogger(app.logger.Handler(), slog.LevelError),
	}

	// Create a shutdownError channel to receive any errors returned by the graceful Shutdown() function
	shutdownError := make(chan error)

	// Start a background goroutine.
	go func() {
		// Create a quit channel which carries os.Signal values.
		quit := make(chan os.Signal, 1)

		// Use signal.Notify() to listen for incoming SIGINT and SIGTER signals and
		// relay them to the quit channel. Any other signals will not be caught by
		// signal.Notify() and will retain their default behavior.
		signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

		// Read the signal from the quit channel. This code will block until a signal
		// is received.
		s := <-quit

		// Log a message to say stopping server. Notice that we also
		// call the String() method on the signal to get the signal name and include it
		// in the log entry attributes.
		app.logger.Info("stopping server", "addr", srv.Addr, "signal", s.String())

		// Call Shutdown() on the server, passing in a empty context with no value or
		// deadline. Shutdown() will return nil if the graceful shutdown was successful,
		// or an error (which may happen because of a problem closing the listeners).
		// We relay this return value to the shutdownError channel.
		shutdownError <- srv.Shutdown(context.Background())
	}()

	app.logger.Info("starting server", "addr", srv.Addr, "env", app.config.env)

	// Calling Shutdown() on the server will cause ListenAndServe() to immediately return
	// a http.ErrServerClosed error. So if we see this error, it is actually a
	// good thing and an indication that the graceful shutdown has started. So we check
	// specifically for this, only returning the error if it is NOT http.ErrServerClosed.
	err := srv.ListenAndServe()
	if !errors.Is(err, http.ErrServerClosed) {
		return err
	}

	// Otherwise, we wait to receive the return value from Shutdown() on the
	// shutdownError channel.
	err = <-shutdownError
	if err != nil {
		return err
	}

	app.logger.Info("waiting for background tasks")
	app.wg.Wait()

	// At this point we know that the graceful shutdown completed successfully and we
	// log a message to indicate that.
	app.logger.Info("shutdown complete")
	return nil
}
