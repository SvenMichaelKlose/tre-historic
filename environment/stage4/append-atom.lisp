;;;;; TRE environment
;;;;; Copyright (c) 2009 Sven Klose <pixel@copei.de>

(defmacro append-atom! (place x)
  `(nconc! ,place (list ,x)))
