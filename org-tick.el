;;; org-tick.el --- An opinionated org-mode utility for managing tickets. --- -*- lexical-binding: t -*-

;;; Commentary:
;;; TODO: Add commentary

;; Author: ohm-en <git@ohm.one>
;; Version: 0.0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: outlines, org
;; URL: https://github.com/ohm-en/org-ticket/

;;; Code:

(defvar org-tick-active-ticket-id)

(require 'cl-lib)
(require 'org-mem)
(require 'magit)

(defgroup org-tick nil
  "Extensions and helpers for Org mode."
  :group 'org
  :prefix "org-tick-")

;; (defcustom org-tick-enable-logging nil
;;   "Whether org-tick should print debug messages."
;;   :type 'boolean
;;   :group 'org-tick)

;;;###autoload
(defun org-tick-version ()
  "Return the org-tick version string."
  (interactive)
  (message "org-tick version %s" "0.0.1"))

;;; Utilities

(defun org-tick--mem-filtered-entries (filter-fn)
  "Return a list of org-mem entries filtered by FILTER-FN."
  (let ((entries (org-mem-all-entries)))
    (cl-remove-if-not filter-fn entries)))

(defun org-tick--mem-get-ticket-entries ()
  "Return a list of tickets as org-mem-entries."
  ;; TODO: Make this customizable
  (org-tick--mem-filtered-entries
   (lambda (e)
     (member "ticket" (org-mem-entry-tags-local e)))))

(defun org-tick--mem-entries-to-completion-options (entries)
  "Take a list of org-mem-entries as ENTRIES and concerts to to (title . entry) for use in read completion."
  (mapcar (lambda (e)
            (cons (org-mem-entry-title e) e))
          entries))

(defun org-tick--mem-get-ticket-completion-options ()
  "Get completion options for org-mem entries filtered by org-tick."
  (org-tick--mem-entries-to-completion-options (org-tick--mem-get-ticket-entries)))

(defun org-tick--mem-goto (entry)
  "Go to the position for ENTRY."
  (cl-assert (org-mem-entry-p entry))
  (find-file (org-mem-entry-file entry))
  (goto-char (org-mem-entry-pos entry)))

(defun org-tick--get-active-ticket ()
  "Return the active org-tick ticket org-mem entry."
  (let ((entry (org-mem-entry-by-id org-tick-active-ticket-id)))
    (cl-assert (org-mem-entry-p entry))
    entry))

(defun org-tick--get-active-ticket-repo-property ()
  "Return the active org-tick ticket's repo property as a path."
  (org-mem-entry-property "REPO" (org-tick--get-active-ticket)))

(defun org-tick--set-active-ticket (entry)
  "Take an ENTRY and set it as the active ticket."
  (cl-assert (org-mem-entry-p entry))
  (setq org-tick-active-ticket-id (org-mem-entry-id entry)))

;;;###autoload
(defun org-tick-open-active-status-magit ()
  "Open the active ticket's repo in magit status."
  (interactive)
  (let* ((repo-property (org-tick--get-active-ticket-repo-property))
         ;; TODO: Add assertion
         (repo-path (file-name-directory (expand-file-name repo-property))))
    (magit-status repo-path)))

;;;###autoload
(defun org-tick-open-active ()
  "Open the active ticket in the current buffer."
  (interactive)
  (org-tick--mem-goto (org-tick--get-active-ticket)))

;;;###autoload
(defun org-tick-find ()
  "Select an active ticket from a list of nodes."
  (interactive)
  (let* ((completion-options (org-tick--mem-get-ticket-completion-options))
         (selected-ticket-title (completing-read "Select ticket: " completion-options))
         (selected-ticket (cdr (assoc selected-ticket-title completion-options))))
    (org-tick--set-active-ticket selected-ticket)
    ;; TODO: Make this help string easier to define.
    (set-transient-map org-tick-ticket-choice-map nil nil
                       "[o] Open  [g] Magit  [q] Quit")
    ))

;;; Keymap
;;;###autoload
(defvar org-tick-ticket-choice-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") #'keyboard-quit)
    (define-key map (kbd "f") #'org-tick-find)
    (define-key map (kbd "o") #'org-tick-open-active)
    (define-key map (kbd "g") #'org-tick-open-active-status-magit)
    map)
  "Prefix keymap for org-ticket ticket choices.")

;;;###autoload
(define-prefix-command 'org-tick-ticket-choice-map)

(provide 'org-tick)
;;; org-tick.el ends here
