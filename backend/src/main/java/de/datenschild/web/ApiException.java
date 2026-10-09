package de.datenschild.web;

import org.springframework.http.HttpStatus;

public class ApiException extends RuntimeException {

    private final HttpStatus status;

    public ApiException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus status() {
        return status;
    }

    public static ApiException notFound() {
        return new ApiException(HttpStatus.NOT_FOUND, "Nicht gefunden");
    }

    public static ApiException tooManyRequests() {
        return new ApiException(HttpStatus.TOO_MANY_REQUESTS, "Zu viele Anfragen – bitte später erneut versuchen");
    }
}
