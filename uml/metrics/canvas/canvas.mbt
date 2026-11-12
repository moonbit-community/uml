///|
#external
priv type CanvasMeasurer

///|
#external
priv type CanvasMeasurement

///|
extern "js" fn new_canvas_measurer() -> CanvasMeasurer =
  #| () => ({ context: null, cache: new Map() })

///|
extern "js" fn CanvasMeasurer::measure(
  self : CanvasMeasurer,
  font : String,
  text : String,
  tab_size : Int32,
) -> CanvasMeasurement =
  #| (self, font, text, tabSize) => {
  #|   if (!self.context) {
  #|     const context = document.createElement("canvas").getContext("2d");
  #|     if (!context) throw new Error("uml/metrics requires a browser Canvas 2D context");
  #|     context.textAlign = "left";
  #|     context.textBaseline = "alphabetic";
  #|     context.direction = "ltr";
  #|     self.context = context;
  #|     // Font loading invalidates fallback-font measurements, including empty-text font bounds.
  #|     const clear = () => self.cache.clear();
  #|     document.fonts.addEventListener("loadingdone", clear);
  #|     document.fonts.addEventListener("loadingerror", clear);
  #|   }
  #|   const key = JSON.stringify([font, text, tabSize]);
  #|   if (self.cache.has(key)) return self.cache.get(key);
  #|   const context = self.context;
  #|   // Invalid CSS must not accidentally reuse the preceding call's font.
  #|   context.font = "10px sans-serif";
  #|   context.font = font;
  #|   // Font line bounds must not depend on the current label's ink or emptiness.
  #|   const bounds = context.measureText("Mg");
  #|   const result = {
  #|     advance: 0, left: 0, right: 0,
  #|     ascent: bounds.fontBoundingBoxAscent, descent: bounds.fontBoundingBoxDescent
  #|   };
  #|   let tabWidth;
  #|   for (const line of text.split("\n")) {
  #|     let advance = 0, left = 0, right = 0;
  #|     const parts = line.split("\t");
  #|     for (let i = 0; i < parts.length; i++) {
  #|       // Shape entire runs; adding individual glyph widths loses kerning and ligatures.
  #|       const measured = context.measureText(parts[i]);
  #|       left = Math.min(left, advance - measured.actualBoundingBoxLeft);
  #|       right = Math.max(right, advance + measured.actualBoundingBoxRight);
  #|       advance += measured.width;
  #|       result.ascent = Math.max(result.ascent, measured.fontBoundingBoxAscent);
  #|       result.descent = Math.max(result.descent, measured.fontBoundingBoxDescent);
  #|       if (i < parts.length - 1) {
  #|         tabWidth ??= context.measureText(" ").width * tabSize;
  #|         if (tabWidth > 0) advance = (Math.floor(advance / tabWidth) + 1) * tabWidth;
  #|       }
  #|     }
  #|     result.advance = Math.max(result.advance, advance);
  #|     result.left = Math.max(result.left, -left);
  #|     result.right = Math.max(result.right, right - advance);
  #|   }
  #|   const cacheLimit = 4096;
  #|   if (self.cache.size >= cacheLimit) self.cache.clear();
  #|   self.cache.set(key, result);
  #|   return result;
  #| }

///|
extern "js" fn CanvasMeasurement::advance(self : CanvasMeasurement) -> Double =
  #| measurement => measurement.advance

///|
extern "js" fn CanvasMeasurement::left(self : CanvasMeasurement) -> Double =
  #| measurement => measurement.left

///|
extern "js" fn CanvasMeasurement::right(self : CanvasMeasurement) -> Double =
  #| measurement => measurement.right

///|
extern "js" fn CanvasMeasurement::ascent(self : CanvasMeasurement) -> Double =
  #| measurement => measurement.ascent

///|
extern "js" fn CanvasMeasurement::descent(self : CanvasMeasurement) -> Double =
  #| measurement => measurement.descent
