import asyncio
import time
from typing import Dict, Optional
from lib.genes.gene_list import GeneList


class FastaCache:
    _instance = None
    _cache: Dict[str, GeneList] = {}
    _locks: Dict[str, asyncio.Lock] = {}
    _last_access: Dict[str, float] = {}
    _cache_ttl = 3600

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = FastaCache()
        return cls._instance

    def __init__(self):
        self._cache = {}
        self._locks = {}
        self._last_access = {}

    async def get_gene_list(self, file_path: str) -> GeneList:
        now = time.time()

        if file_path not in self._locks:
            self._locks[file_path] = asyncio.Lock()

        if file_path in self._cache and now - self._last_access[file_path] < self._cache_ttl:
            self._last_access[file_path] = now
            return self._cache[file_path]

        async with self._locks[file_path]:
            if file_path in self._cache and now - self._last_access[file_path] < self._cache_ttl:
                self._last_access[file_path] = now
                return self._cache[file_path]


            async def _load():
                import aiofiles
                async with aiofiles.open(file_path, 'r') as f:
                    data = await f.read()

                genes, errors = await GeneList.parse_fasta(data)
                return GeneList.from_list(genes=genes, errors=errors)

            gene_list = await _load()

            self._cache[file_path] = gene_list
            self._last_access[file_path] = now

            return gene_list