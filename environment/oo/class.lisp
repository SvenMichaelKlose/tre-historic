(defstruct %slot
  flags ; (:static :protected :private)
  type  ; (:method :member)
  name
  args
  body)

(fn %slot-flag? (slot flag)
  (member flag (%slot-flags slot)))

(defstruct class
  (name   nil)
  (base   nil)
  (slots  nil)
  (parent nil)
  (constructor-maker nil))

(fn class-slot? (cls name)
  (member [eq name (%slot-name _)]
          (class-slots cls)))

(fn class-slot-by-name (cls name)
  (aprog1 (find-if [eq name (%slot-name _)]
                   (class-slots cls))
    (unless !
      (error "Class ~A has no slot ~A"
             (class-name cls) name))))

(fn class-slots-by-type (cls type)
  (remove-if-not [eq type (%slot-type _)]
                 (class-slots cls)))

(fn class-methods (cls)
  (class-slots-by-type cls :method))

(fn class-members (cls)
  (class-slots-by-type cls :member))
