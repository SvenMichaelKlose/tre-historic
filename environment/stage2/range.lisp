(functional range?)

(fn range? (x bottom top)
  (& (>= x bottom)
     (<= x top)))
