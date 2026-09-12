package com.litha.api.controller;

import com.litha.api.repository.HuntItemRepository;
import com.litha.api.repository.MemoryRepository;
import com.litha.api.repository.StonePhotoRepository;
import com.litha.api.model.Stone;
import com.litha.api.repository.StoneRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/stones")
public class StoneController extends CrudController<Stone> {
    private final StoneRepository repo;
    private final StonePhotoRepository photos;
    private final MemoryRepository memories;
    private final HuntItemRepository hunts;

    public StoneController(StoneRepository repo, StonePhotoRepository photos,
            MemoryRepository memories, HuntItemRepository hunts) {
        this.repo = repo;
        this.photos = photos;
        this.memories = memories;
        this.hunts = hunts;
    }

    @Override
    protected JpaRepository<Stone, Long> repository() {
        return repo;
    }

    @Override
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void delete(@PathVariable Long id) {
        if (!repo.existsById(id)) {
            throw new ResourceNotFoundException(id);
        }
        hunts.findByStone_Id(id).forEach(hunt -> hunt.stone = null);
        photos.deleteByStone_Id(id);
        memories.deleteByStone_Id(id);
        repo.deleteById(id);
    }
}
