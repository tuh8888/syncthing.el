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

(defun syncthing|parent-dir-files (file)
  (directory-files (file-name-directory (directory-file-name file)) t))

(defun syncthing|all-sync-conflicts (file)
  (remove-if-not (lambda (file)
                   (cl-search "sync-conflict" file))
                 (syncthing|parent-dir-files file)))

(defun syncthing|local-file (conflicting-file)
  (first (remove-if-not (lambda (file)
                          (let ((file-name (file-name-base file)))
                            (and (not (or (equal conflicting-file file)
                                          (equal file-name ".")
                                          (equal file-name "..")))
                                 (cl-search file-name conflicting-file)
                                 (= (+ 1
                                       (cl-search file-name conflicting-file)
                                       (length file-name))
                                    (cl-search "sync-conflict" conflicting-file)))))
                        (syncthing|parent-dir-files conflicting-file))))
(let ((file-name "refile"))
)

(defun syncthing|ediff (conflicting-file)
  (interactive (list (read-file-name "File: "
                                     (file-name-directory (directory-file-name (buffer-file-name)))
                                     nil
                                     t
                                     nil
                                     (lambda (file)
                                       (cl-search "sync-conflict" file)))))
  (ediff (syncthing|local-file conflicting-file) conflicting-file))

(provide 'syncthing)

;;; syncthing.el ends here
