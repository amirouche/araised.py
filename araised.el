;;; araised.el --- Run araised on the Python callable at point -*- lexical-binding: t -*-

(defun araised--project-root ()
  (or (locate-dominating-file default-directory "pyproject.toml")
      (locate-dominating-file default-directory "setup.py")
      default-directory))

(defun araised--module-path ()
  (let* ((root (araised--project-root))
         (rel  (file-relative-name (buffer-file-name) root))
         (bare (file-name-sans-extension rel)))
    (replace-regexp-in-string "[/\\\\]" "." bare)))

(defun araised--callable ()
  (or (python-info-current-defun)
      (error "araised: no Python def at point")))

(defun araised-at-point (target)
  "Run araised on TARGET (module.path:callable) and show results."
  (interactive
   (list (read-string "araised target: "
                      (format "%s:%s" (araised--module-path) (araised--callable)))))
  (let ((buf (get-buffer-create "*araised*")))
    (with-current-buffer buf
      (setq buffer-read-only nil)
      (erase-buffer)
      (if (zerop (call-process "araised" nil buf nil target))
          (message "araised: done")
        (message "araised: error — see *araised* buffer"))
      (setq buffer-read-only t))
    (display-buffer buf)))

(provide 'araised)
;;; araised.el ends here
