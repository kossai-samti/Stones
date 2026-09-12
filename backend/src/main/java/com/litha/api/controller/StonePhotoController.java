package com.litha.api.controller;

import com.litha.api.model.StonePhoto;
import com.litha.api.repository.StonePhotoRepository;
import com.litha.api.repository.StoneRepository;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/stone-photos")
public class StonePhotoController extends CrudController<StonePhoto> {
    private final StonePhotoRepository repo;
    private final StoneRepository stones;

    public StonePhotoController(StonePhotoRepository repo, StoneRepository stones) {
        this.repo = repo;
        this.stones = stones;
    }

    @Override
    protected JpaRepository<StonePhoto, Long> repository() {
        return repo;
    }

    @Override
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public StonePhoto create(@RequestBody StonePhoto photo) {
        if (photo.stone == null || photo.stone.id == null) {
            throw new IllegalArgumentException("A stone is required for a photo");
        }
        photo.stone = stones.findById(photo.stone.id)
                .orElseThrow(() -> new ResourceNotFoundException(photo.stone.id));
        return repo.save(photo);
    }

    @GetMapping(params = "stoneId")
    public List<StonePhoto> byStone(@RequestParam Long stoneId) {
        return repo.findByStone_IdOrderByDisplayOrder(stoneId);
    }
}
