;;; org-projectile-note-mode.el --- -*- lexical-binding: t; -*-

(require 'projectile)

;; (defvar org-projectile-note-mode nil)
(setq org-projectile-projects-file "~/study/projects.org")

(defcustom org-projectile-note-storage-path (concat org-directory "projects")
  "hard link path")

(defun org-projectile-note--str ()
  "returns the absolute path of a project specific note file. time stamp
is included to prevent name collisions"
  (let* ((path (projectile-project-root))
         (name (file-dir-base-name (projectile-project-root)))
         (time (format-time-string "%m%d%y-%H%M%S.org")))
    (concat path name "-notes-" time)))

(defun org-projectile-note--file-exists ()
  (let* ((dir (projectile-project-root))
         (files (directory-files dir t))
         (project-name (file-dir-base-name dir))
         (note-name (org-projectile-note--str))
         (re (concat project-name "-notes-[0-9]*-[0-9]*.org"))
         (note-file (-find (lambda (x) (when (string-match re x) x)) files)))
    (cond (note-file note-file)
          (t note-name))))

(defun org-projectile-note-create (&optional arg)
  ;; create a file named PROJECT-NAME-notes.org
  (interactive)
  (let* ((path (org-projectile-note--file-exists))
         (note (concat (projectile-project-root) path))
         (file (file-name note)))

    (cond ((not (file-exists-p path))
           (find-file path)
           (insert (concat  "#+TITLE:" (projectile-project-root) "\n\n"))
           (save-buffer)
           ;; create hardlink in `org-directory'
           (unless (file-exists-p org-projectile-note-storage-path)
             (mkdir org-projectile-note-storage-path)
             (dired-hardlink path (concat org-projectile-note-storage-path "/" file)))
           ;; open file
           (when arg
             (find-file note)))
          (t (message "note file exists - %S" path)))))

(defun org-projectile-note-select-project ()
  "Select a project and switch to its note file, create one if non-existant."
  (interactive)
  (let* ((dir (ivy-read "select project: "(projectile-relevant-known-projects)))
         (files (directory-files dir t))
         (project-name (file-dir-base-name dir))
         (new-name (concat project-name "-notes-" (format-time-string "%m%d%y-%H%M%S.org")))
         (re (concat project-name "-notes-[0-9]*-[0-9]*.org"))
         (note-file (-find (lambda (x) (when (string-match re x) x)) files)))
    (cond
     ;; open note file if it exists
     (note-file (find-file note-file))
     ;; open project in dired buffer and create note file
     (t (dired dir)
        (org-projectile-note-create)))))

(defun org-projectile-note-select-current-note ()
  "Select the current project's note file, if none exists create one and switch to it"
  (interactive)
  (when-let* ((path (org-projectile-note--file-exists))
              (inside-project? (projectile-project-root)))
    (cond ((file-exists-p path)
           (find-file path))
          (t (org-projectile-note-create "switch")))))

(define-minor-mode org-projectile-note-mode
  "automatically create a file specific to the project. switching to a
project using projectile will open the project's org file first"
  :init-value nil
  :global t
  :variable org-projectile-note-mode
  :group 'org-projectile-note-mode

  (cond (org-projectile-note-mode (add-hook 'projectile-after-switch-project-hook 'org-projectile-note-create))
        (t (remove-hook 'projectile-after-switch-project-hook 'org-projectile-note-create))))

(provide 'org-projectile-note-mode)

