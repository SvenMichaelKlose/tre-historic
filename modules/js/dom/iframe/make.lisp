(fn make-iframe (html-document &key (ns nil))
  (alet (make-extended-element "iframe" :ns ns :doc html-document)
    (!.hide)
    (html-document.body.add-front !)
    (iframe-extend !)))
