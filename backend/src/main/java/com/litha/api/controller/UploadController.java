package com.litha.api.controller;

import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.MediaTypeFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.nio.file.*;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/uploads")
public class UploadController {
    private final Path directory = Path.of("uploads").toAbsolutePath().normalize();
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, String> upload(@RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty()) throw new IllegalArgumentException("A photo is required");
        Files.createDirectories(directory);
        String original = file.getOriginalFilename() == null ? "photo.jpg" : file.getOriginalFilename();
        String extension = original.lastIndexOf('.') >= 0 ? original.substring(original.lastIndexOf('.')) : ".jpg";
        String filename = UUID.randomUUID() + extension.toLowerCase();
        Files.copy(file.getInputStream(), directory.resolve(filename), StandardCopyOption.REPLACE_EXISTING);
        return Map.of("path", "/api/uploads/" + filename);
    }
    @GetMapping("/{filename:.+}")
    public ResponseEntity<Resource> view(@PathVariable String filename) {
        Path file = directory.resolve(filename).normalize();
        if (!file.startsWith(directory) || !Files.exists(file)) return ResponseEntity.notFound().build();
        return ResponseEntity.ok().contentType(MediaTypeFactory.getMediaType(file.getFileName().toString()).orElse(MediaType.APPLICATION_OCTET_STREAM)).body(new FileSystemResource(file));
    }
}
