;;; syncthing.el --- summary -*- lexical-binding: t -*-

;; Author: Harrison Pielke-Lombardo
;; Maintainer: Harrison Pielke-Lombardo
;; Version: 1.0.0
;; Package-Requires: (cl-lib)
;; Homepage: www.github.com/tuh8888/syncthing.el
;; Keywords:


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'cl-lib)

(defun syncthing|parent-dir (file)
  (file-name-directory (directory-file-name file)))

(defun syncthing|parent-dir-files (file)
  (directory-files (syncthing|parent-dir file) t))

(defun syncthing|conflicting-file-p (file)
  (cl-search "sync-conflict" file))

(defun syncthing|all-sync-conflicts (file)
  (remove-if-not #'syncthing|conflicting-file-p (syncthing|parent-dir-files file)))

(defun syncthing|local-file-p (file conflicting-file)
  (let ((file-name (file-name-base file)))
    (and (not (or (equal conflicting-file file)
                  (equal file-name ".")
                  (equal file-name "..")))
         (when-let ((idx (cl-search file-name conflicting-file)))
           (= (+ 1 idx (length file-name))
              (cl-search "sync-conflict" conflicting-file))))))

(defun syncthing|local-file (conflicting-file)
  (first (remove-if-not (lambda (file)
                          (syncthing|local-file-p file conflicting-file))
                        (syncthing|parent-dir-files conflicting-file))))

(defun syncthing|ediff (conflicting-file)
  (interactive
   (let ((dir (if (eq major-mode 'dired-mode)
                  (dired-current-directory)
                default-directory)))
     (list (read-file-name "File: " dir nil t nil #'syncthing|conflicting-file-p))))
  (ediff (syncthing|local-file conflicting-file) conflicting-file))

(defun syncthing|current-buffer-file-to-sync-conflict ()
  (let* ((file-name (buffer-file-name))
         (new-file-name (concat (file-name-directory file-name)
                                (file-name-base file-name)
                                "-sync-conflict."
                                (file-name-extension file-name))))
    (rename-buffer new-file-name)
    (rename-file file-name new-file-name)
    (set-visited-file-name new-file-name)
    (set-buffer-modified-p nil)))

(defun syncthing|sync-conflict-file-name (filename)
  (concat (file-name-directory filename)
          (file-name-base filename)
          "-sync-conflict."
          (file-name-extension filename)))


(defun syncthing|file-name-sans-sync-conflict (filename)
  (concat (file-name-directory filename)
          (replace-regexp-in-string "-sync-conflict$" "" (file-name-base filename))
          "."
          (file-name-extension filename)))

(defun syncthing|rename-current-buffer-file-to-sync-conflict ()
  "Rename the current buffer and its file so that it register's as a sync conflict with itself."
  (interactive)
  (let* ((old-short-name (buffer-name))
         (old-filename (buffer-file-name))
         (old-dir (file-name-directory old-filename))
         (new-name (if (syncthing|conflicting-file-p old-filename)
                       (syncthing|file-name-sans-sync-conflict old-filename)
                     (syncthing|sync-conflict-file-name old-filename)))
         (new-dir (file-name-directory new-name))
         (new-short-name (file-name-nondirectory new-name))
         (file-moved-p (not (string-equal new-dir old-dir)))
         (file-renamed-p (not (string-equal new-short-name old-short-name))))
    (cond ((get-buffer new-name)
           (error "A buffer named '%s' already exists!" new-name))
          (t
           (let ((old-directory (file-name-directory new-name)))
             (when (and (not (file-exists-p old-directory))
                        (yes-or-no-p
                         (format "Create directory '%s'?" old-directory)))
               (make-directory old-directory t)))
           (rename-file old-filename new-name 1)
           (rename-buffer new-name)
           (set-visited-file-name new-name)
           (set-buffer-modified-p nil)
           (when (fboundp 'recentf-add-file)
             (recentf-add-file new-name)
             (recentf-remove-if-non-kept old-filename))
           (when (and (configuration-layer/package-used-p 'projectile)
                      (projectile-project-p))
             (call-interactively #'projectile-invalidate-cache))
           (message (cond ((and file-moved-p file-renamed-p)
                           (concat "File Moved & Renamed\n"
                                   "From: " old-filename "\n"
                                   "To:   " new-name))
                          (file-moved-p
                           (concat "File Moved\n"
                                   "From: " old-filename "\n"
                                   "To:   " new-name))
                          (file-renamed-p
                           (concat "File Renamed\n"
                                   "From: " old-short-name "\n"
                                   "To:   " new-short-name))))))))


(provide 'syncthing)

;;; syncthing.el ends here
