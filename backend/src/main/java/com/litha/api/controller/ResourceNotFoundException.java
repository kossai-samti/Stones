package com.litha.api.controller;

import org.springframework.http.HttpStatus; import org.springframework.web.bind.annotation.ResponseStatus;
@ResponseStatus(HttpStatus.NOT_FOUND)
public class ResourceNotFoundException extends RuntimeException { public ResourceNotFoundException(Long id) { super("Resource not found: " + id); } }
