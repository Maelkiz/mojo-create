from create.core import *


@fieldwise_init
struct Life(Headless, Movable, Deinitable):
    comptime WIDTH: Int = 60
    comptime HEIGHT: Int = 25

    comptime STEP_INTERVAL: Float64 = 0.1

    var cells: List[Bool]
    var scratch: List[Bool]
    var generation: Int
    var accumulator: Float64

    @staticmethod
    def create(mut ctx: Context) raises -> Life:
        var cells = List[Bool](length=Life.WIDTH * Life.HEIGHT, fill=False)

        # R-pentomino near center
        var cx = Life.WIDTH // 2
        var cy = Life.HEIGHT // 2
        cells[cy * Life.WIDTH + cx + 1] = True
        cells[cy * Life.WIDTH + cx + 2] = True
        cells[(cy + 1) * Life.WIDTH + cx] = True
        cells[(cy + 1) * Life.WIDTH + cx + 1] = True
        cells[(cy + 2) * Life.WIDTH + cx + 1] = True

        return Life(
            cells^,
            List[Bool](length=Life.WIDTH * Life.HEIGHT, fill=False),
            0,
            0.0,
        )

    def update(mut self, mut ctx: Context) raises:
        self.accumulator += ctx.time.delta_time
        if self.accumulator < Life.STEP_INTERVAL:
            return
        self.accumulator -= Life.STEP_INTERVAL
        if self.generation >= 300:
            ctx._canvas.close()
            return
        self._step()
        self._draw()
        self.generation += 1

    def _at(self, x: Int, y: Int) -> Bool:
        if x < 0 or x >= Life.WIDTH or y < 0 or y >= Life.HEIGHT:
            return False
        return self.cells[y * Life.WIDTH + x]

    def _step(mut self):
        for y in range(Life.HEIGHT):
            for x in range(Life.WIDTH):
                var n = 0
                for dy in range(-1, 2):
                    for dx in range(-1, 2):
                        if dx == 0 and dy == 0:
                            continue
                        if self._at(x + dx, y + dy):
                            n += 1
                var alive = self.cells[y * Life.WIDTH + x]
                self.scratch[y * Life.WIDTH + x] = (alive and (n == 2 or n == 3)) or (not alive and n == 3)
        for i in range(Life.WIDTH * Life.HEIGHT):
            self.cells[i] = self.scratch[i]

    def _draw(self) raises:
        print("\033[H\033[2J", end="")
        print("Generation:", self.generation)
        for y in range(Life.HEIGHT):
            var row = String()
            for x in range(Life.WIDTH):
                row += "█" if self.cells[y * Life.WIDTH + x] else " "
            print(row)


def main() raises:
    run[Life]("Life", 1, 1)
