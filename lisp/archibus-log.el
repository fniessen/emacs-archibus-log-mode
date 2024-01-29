;;; archibus-log.el -- major mode for viewing ARCHIBUS Log files

;; Copyright (c) 2016-2024 Fabrice Niessen

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA

;; Author: Fabrice Niessen
;; Keywords: mode archibus log file

;;; Commentary:

;; http://logging.apache.org/log4j/docs/api/org/apache/log4j/PatternLayout.html for instructions on
;; changing the information provided by the ConversionPattern.  [%d] adds date and time; [%-5p]
;; priority in a 5 character-wide column; [%l] calling method and line number; [%m] adds the message
;; itself; %n adds the platform-dependent newline character.  Removing [%l] will improve performance
;; slightly.
;; -->
;; <!DOCTYPE log4j:configuration SYSTEM "log4j.dtd">
;; <log4j:configuration xmlns:log4j="http://jakarta.apache.org/log4j/">
;; <!--
;; The file appender dictates what information appears in the archibus/WEB-INF/log/archibus.log file.
;; The [%C{1}] outputs class name, which is performance hit; for developent mode only! TODO: Remove
;; before production.

;;; Code:

;; Check out ~log4j-mode~ instead?  And nice colors at
;; https://www.jetbrains.com/resharper/help/Regular_Expressions_Assistance.html.

(defvar ablog-ignored-class-names
  '("AbstractBeanFactory"
    "AbstractTablesLoader"
    "Authenticated"
    "AutowiredAnnotationBeanPostProcessor"
    "CSSImportSimpleTag"
    "ClasspathHacker"
    "CommonHandler"
    "Config"
    "ConfigManagerImpl"
    "Context"
    ;; "ContextFilter"
    "ContextImpl"
    "DataEventTriggerTemplate"
    "DataSourceDefLoader"
    "DataSourceImpl"
    "DataSourceRestrictionConverter"
    "DataSourceSimpleTag"
    "DatabaseImpl"
    "DefaultListableBeanFactory"
    "DefaultSecurityFilterChain"
    "DispatchFilter"
    "DrawingManagementServiceImpl"
    "Engine"
    "ExpressionSqlFormatter"
    "FieldFormula"
    "FieldOperation"
    "FileHelper"
    "FileIndex"
    "FileIndex$1"
    "JSImportSimpleTag"
    "JobManagerImpl"
    "LicenseCounterImpl"
    "LicenseManagerImpl"
    "LicenseManagerLoader"
    "LicenseValuesLoader"
    "LocalizedStringsLoader"
    "LoggingPropertyPlaceholderConfigurer"
    "NavigationPagesPublisher"
    "NotAuthenticated"
    "PanelDefLoader"
    "PooledDbDriverImpl"
    "ProjectImpl"
    "PropertiesLoaderSupport"
    "QueryDefImplBase"
    "RecordPersistenceImpl"
    "RecordsPersistenceImpl"
    "RenderingFilter"
    "Report"
    "ReportBuilder"
    "ReportDefImplicitGenerator"
    "ReportDefLoader"
    "ReportDefMerger"
    "ReportDefProcessor"
    "ReportDefValidator"
    "RestrictionForFieldsImpl"
    "RestrictionParsedImpl"
    "SecurityControllerImpl"
    "SecurityControllerTemplate"
    "SecurityNamespaceHandler"
    "SimpleTagBase"
    "SpringSecurityCoreVersion"
    "StepImpl"
    "TablesLoaderDeleteImpl"
    "TablesLoaderUpdateImpl"
    "TransactionTemplate"
    "ViewSimpleTag"
    "WorkflowRulesContainerLoader"
    "XmlBeanDefinitionReader")
  "*All class names that are in this list will be ignored.")

(defvar ablog-highlighted-class-names
  '("AbstractApplicationContext"
    "CascadeDeleteImpl"
    "CascadeHandlerImpl"
    "CascadeUpdateImpl"
    "ConfigManagerLoader"
    "ConnectorService"
    "ContextFilter"
    "CostIndexingService"
    "DataSourceFactory"
    "DatabaseLoader"
    "DefaultSingletonBeanRegistry"
    "EscalationHandler"
    "HandleCircularReferences"
    "HelpdeskEventHandlerBase"
    "LeaseAdministrationAlertsHandler"
    "MaintenanceMobileService"
    "MoveCommonUtil"
    "MovesHandler"
    "PmScheduleGenerator"
    "PmWorkOrderGenerator"
    "PreventiveMaintenanceCommonHandler"
    "ProjectLoader"
    "StepManagerImpl"
    "WorkflowRulesContainerImpl")
  "*All class names that are in this list will be highlighted.")

(defface ablog-bold-face
  '((t :weight bold))
  "Font face for logging priority level.")

(defface ablog-priority-face
  '((t :foreground "#17AC69"))
  "Font face for logging priority level.")

(defface ablog-time-face
  '((t :foreground "#008ED1"))
  "font face for sql")

(defface ablog-time-highlighted-face
  '((t :foreground "magenta"))
  "font face for sql")

(defface ablog-time-updated-face
  '((t :foreground "#FF8001"))
  "font face for sql")

(defface ablog-time-warning-face
  '((t :weight bold :foreground "#FB9500" :background "#FFFBD5"))
  "font face for timestamp of warning lines")

(defface ablog-time-error-face
  '((t :foreground "#C12E2A"))
  "font face for error lines")

(defface ablog-number-of-records-face
  '((t :weight bold :foreground "blue"))
  "font face for sql")

(defface ablog-time-1-record-updated-face
  '((t :weight bold :foreground "#3B8416"))
  "font face for sql")

(defface ablog-msg-1-record-updated-face
  '((t :weight bold :foreground "#3B8416" :background "#EFFFEF"))
 "font face for sql")

(defface ablog-time-mult-records-updated-face
  '((t :weight bold :foreground "#FF8001"))
  "font face for sql")

(defface ablog-msg-mult-records-updated-face
  '((t :weight bold :foreground "#FF8001" :background "#EFFFEF"))
  "font face for sql")

(defface ablog-time-no-records-updated-face
  '((t :weight bold :foreground "red"))
  "font face for sql")

(defface ablog-msg-no-records-updated-face
  '((t :weight bold :foreground "red" :background "#FFEFEF"))
  "font face for sql")

(defface ablog-class-name-face
  '((t :foreground "green4"))
  "font face for sql")

(defface ablog-ignore-face
  '((t :foreground "#C9C9C9"))          ; #D4D4D4.
  "font face for sql")

(defface ablog-sql-insert-face
  '((t :foreground "#3B8416" :background "#E5F0CB"))
  "Face for highlighting SQL INSERT statements in log file.")

(defface ablog-sql-select-face
  '((t :foreground "#FF8001" :background "#FFFFCC"))
  "Face for highlighting SQL SELECT statements in log file.")

(defface ablog-sql-update-face
  '((t :foreground "#3A87AD" :background "#D9EDF7"))
  "Face for highlighting SQL UPDATE statements in log file.")

(defface ablog-sql-delete-face
  '((t :foreground "#B94A48" :background "#F2DEDE"))
  "Face for highlighting SQL DELETE statements in log file.")

(defface ablog-sql-alter-face
  '((t :weight bold :foreground "white" :background "#0173C7"))
  "Face for highlighting SQL ALTER statements in log file.")

(defface ablog-highlight-face
  '((t :foreground "magenta"))
  "font face for highlighting special lines")

(defface ablog-highlight-id-face
  '((t :foreground "#0074E8"))
  "Font face for logging priority level.")

(defface ablog-highlight-string-face
  '((t :weight bold :foreground "#DD00A9"))
  "font face for highlighting strings")

(defface ablog-highlight-number-face
  '((t :weight bold :foreground "#058B00"))
  "font face for highlighting numbers")

(defface ablog-highlight-null-face
  '((t :foreground "#737373"))
  "font face for highlighting NULL keyword")

(defface ablog-warning-face
  '((t :weight bold :foreground "#715100" :background "#FFFBD5"))
  "font face for warning lines")

(defface ablog-error-face
  '((t :weight bold :foreground "#FF3125" :background "#FFFF88"))
  "font face for error lines")

(defface ablog-stack-trace-archibus-face
  '((t :weight bold :foreground "#C12E2A"))
  "font face for error lines")

(defface ablog-stack-trace-face
  '((t :foreground "#C12E2A"))
  "font face for error lines")

(defface ablog-separator-face
  '((t :overline "red" :background "#FFF3F3"))
  "font face for separator lines")

(defface ablog-sub-separator-face
  '((t :overline "red"))
  "font face for sub-separator lines") ;; sub-requests (within a click-operation).

(defface ablog-stack-trace-separator-face
  '((t :overline "red" :foreground "#C9C9C9"))
  "font face for separator lines in stack traces")

;; Constants.
(defconst ablog-error-regexp
  "\\(\\[ERROR\\]\\|ruleFailed\\|Rule.* failed\\)"
  "Regexp to recognize errors in the ARCHIBUS log file.")

(defconst ablog-sql-read-or-change-regexp
  "\\(DbConnectionImpl\\|ArSqlUtils\\)"
  "Regexp to recognize SQL statements in the ARCHIBUS log file.")

(defconst ablog-sql-read-regexp
  "\\(DbConnectionImpl\\|ArSqlUtils\\)\\] - \\[ *\\([Ss][Ee][Ll][Ee][Cc][Tt]\\) "
  "Regexp to recognize SQL read statements in the ARCHIBUS log file.")

(defconst ablog-sql-change-regexp
  "\\(DbConnectionImpl\\|ArSqlUtils\\).*\\([Ii][Nn][Ss][Ee][Rr][Tt] [Ii][Nn][Tt][Oo]\\|[Uu][Pp][Dd][Aa][Tt][Ee]\\|[Dd][Ee][Ll][Ee][Tt][Ee] [Ff][Rr][Oo][Mm]\\|[Aa][Ll][Tt][Ee][Rr]\\|MERGE\\|merge\\|Merge\\|TRUNCATE TABLE\\|TRUNCATE table\\|BEGIN EXECUTE IMMEDIATE\\|CREATE INDEX\\|CREATE OR REPLACE VIEW\\|CREATE VIEW\\|ALTER VIEW\\|DROP VIEW\\) "
  "Regexp to recognize SQL modification statements in the ARCHIBUS log file.")

;;; Key map.
(defvar ablog-map
  (let ((map (make-sparse-keymap))
        (bindings '(("D" . ablog-previous-read-or-change)
                    ("d" . ablog-next-read-or-change)
                    ("R" . ablog-previous-read)
                    ("r" . ablog-next-read)
                    ("W" . ablog-previous-change)
                    ("w" . ablog-next-change)
                    ("E" . ablog-previous-error)
                    ("e" . ablog-next-error)
                    ("H" . ablog-previous-highlighted-class)
                    ("h" . ablog-next-highlighted-class)
                    ("C-a" . ablog-move-beginning-of-line)
                    ("C-x C-j" . nil)))) ; Disable dired-jump.

    ;; Set parent map for ablog-map.
    (set-keymap-parent map special-mode-map)

    ;; Define key bindings.
    (dolist (binding bindings)
      (define-key map (kbd (car binding)) (cdr binding)))

    map)
  "Keymap for ablog buffers.")

(defun ablog-highlight-fields ()
  "Highlight ARCHIBUS log file."
  (interactive)

  (setq font-lock-multiline t)

  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\([^\]]*\\)\\] - \\[.*\\]"
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face))))
  (font-lock-add-keywords
   nil
   '(("\\(	at .*\\)\\((\\)\\(.*.java\\):\\(.*\\)\\()\\)"
      (1 'ablog-stack-trace-face)
      (2 'ablog-ignore-face)
      (3 'ablog-class-name-face)
      (4 'ablog-time-face)
      (5 'ablog-ignore-face))))
  (font-lock-add-keywords
   nil
   '(("\\(	at com.archibus.\\)\\(.*\\)\\.\\(.*\\)\\((\\)\\(.*.java\\):\\(.*\\)\\()\\)"
      (1 'ablog-stack-trace-face)
      (2 'ablog-stack-trace-archibus-face)
      (3 'ablog-time-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'ablog-time-face)
      (7 'ablog-ignore-face))))
  (font-lock-add-keywords
   nil
   `((,(concat "\\[\\([^\]]*\\)\\]\\[\\([^\]]*\\)\\]\\["
               (regexp-opt ablog-ignored-class-names 'paren)
               "\\] - \\[\\(.*\\)\\]")
      (1 'ablog-ignore-face)
      (2 'ablog-ignore-face)
      (3 'ablog-ignore-face)
      (4 'ablog-ignore-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([^\]]*\\)\\]\\[\\(DbConnectionImpl\\)\\] - \\[\\(SET CONCAT_NULL_YIELDS_NULL OFF.*\\|Updated: -1 records\\|\\*\\*\\*COMMIT\\*\\*\\*\\)\\]"
      (1 'ablog-ignore-face)
      (2 'ablog-ignore-face)
      (3 'ablog-ignore-face)
      (4 'ablog-ignore-face))))
  (font-lock-add-keywords
   nil
   `((,(concat "\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\["
               (regexp-opt ablog-highlighted-class-names 'paren)
               "\\] - \\[\\(.*\\)\\]")
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-highlighted-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'ablog-highlight-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\(DbConnectionImpl\\)\\] - \\[\\(Updated: \\)\\(1\\)\\( records\\)\\]"
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-1-record-updated-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'font-lock-keyword-face)
      (7 'ablog-msg-1-record-updated-face)
      (8 'ablog-msg-1-record-updated-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\(DbConnectionImpl\\)\\] - \\[\\(Updated: \\)\\([0-9]*\\)\\( records\\)\\]"
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-mult-records-updated-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'font-lock-keyword-face)
      (7 'ablog-msg-mult-records-updated-face)
      (8 'ablog-msg-mult-records-updated-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\(DbConnectionImpl\\)\\] - \\[\\(Updated: \\)\\(1\\)\\( record\\)\\(s\\)\\]"
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-1-record-updated-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'font-lock-keyword-face)
      (7 'ablog-msg-1-record-updated-face)
      (8 'ablog-msg-1-record-updated-face)
      (9 'ablog-ignore-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\(DbConnectionImpl\\)\\] - \\[\\(Updated: \\)\\(0\\)\\( records\\)\\]"
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-no-records-updated-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'font-lock-keyword-face)
      (7 'ablog-msg-no-records-updated-face)
      (8 'ablog-msg-no-records-updated-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\(DbConnectionImpl\\|ArSqlUtils\\)\\] - \\[\\([a-zA-Z ]?\\(INSERT\\|insert\\|Insert\\) .*\\)\\]"
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'ablog-sql-insert-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\(DbConnectionImpl\\|ArSqlUtils\\)\\] - \\[\\(\\*\\*\\*\\*\\*\\*\\* user_pwd \\*\\*\\*\\*\\*\\*\\*.*\\)\\]"
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'ablog-sql-insert-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\(DbConnectionImpl\\|ArSqlUtils\\)\\] - \\[\\( ?\\(SELECT\\|select\\|Select\\) .*\\)\\]"
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'ablog-sql-select-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\(DbConnectionImpl\\|ArSqlUtils\\)\\] - \\[\\( *\\(UPDATE\\|update\\|Update\\|MERGE\\|merge\\|Merge\\) .*\\)\\]"
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'ablog-sql-update-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\(DbConnectionImpl\\|ArSqlUtils\\)\\] - \\[\\( ?\\(ALTER\\|alter\\|Alter\\|TRUNCATE TABLE\\|BEGIN EXECUTE IMMEDIATE\\|CREATE INDEX\\|CREATE OR REPLACE VIEW\\|CREATE VIEW\\|ALTER VIEW\\) .*\\)\\]"
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'ablog-sql-alter-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\(DbConnectionImpl\\|ArSqlUtils\\)\\] - \\[\\(.*\\(DROP INDEX\\|DROP VIEW\\) .*\\)\\]"
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'ablog-sql-alter-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\(DbConnectionImpl\\|ArSqlUtils\\)\\] - \\[\\( ?\\(DELETE\\|delete\\|Delete\\) .*\\)\\]"
      (1 'ablog-priority-face)
      (2 'ablog-ignore-face)
      (3 'ablog-time-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'ablog-sql-delete-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\([^\]]*\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\([^\]]*\\)\\] - \\[\\(\\*\\*\\*ROLLBACK\\*\\*\\*\\)\\]"
      (1 'ablog-ignore-face)
      (2 'ablog-time-error-face)
      (3 'ablog-time-error-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'ablog-error-face))))

  ;; At the end, they must preempt previously applied colors...
  (font-lock-add-keywords
   nil
   '(("\\[\\(WARN \\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\([^\]]*\\)\\] - \\[\\(.*\\)\\]"
      (1 'ablog-warning-face)
      (2 'ablog-time-warning-face)
      (3 'ablog-time-warning-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'ablog-warning-face))))
  (font-lock-add-keywords
   nil
   '(("\\(workflow rule = .*\\|Result message = .*\\|com.archibus.utility.ExceptionBase\\|.*SQL.*Exception: .*\\|Caused by: .*\\)"
      (1 'ablog-error-face))))
  (font-lock-add-keywords
   nil
   '(("\\[\\(ERROR\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\([^\]]*\\)\\] - \\[\\(.*\\)"
                                        ; Final bracket is not always present.
      (1 'ablog-error-face)
      (2 'ablog-time-error-face)
      (3 'ablog-time-error-face)
      (4 'ablog-ignore-face)
      (5 'ablog-class-name-face)
      (6 'ablog-error-face))))
  ;; (font-lock-add-keywords
  ;;  nil
  ;;  '(("\\('[^']*'\\)"
  ;;     (1 'ablog-time-face))))
  (font-lock-add-keywords
   nil
   '(("\\(\\[DEBUG\\]\\[[0-9-]* [0-9:]*,[0-9]*\\]\\[ContextFilter\\] - \\[\\+\\+\\+\\+\\+\\+\\+\\+\\+\\+ Request=\\[.*\\)"
      (1 'ablog-sub-separator-face))))
  ;; (font-lock-add-keywords
  ;;  nil
  ;;  '(("\\[\\(DEBUG\\)\\]\\[\\([0-9-]* \\)\\([0-9:]*\\)\\(,[0-9]*\\)\\]\\[\\(ContextFilter\\)\\] - \\[\\(\\+\\+\\+\\+\\+\\+\\+\\+\\+\\+ Request=\\[\\)"
  ;;     (1 'ablog-priority-face)
  ;;     (2 'ablog-ignore-face)
  ;;     (3 'ablog-time-highlighted-face)
  ;;     (4 'ablog-ignore-face)
  ;;     (5 'ablog-class-name-face)
  ;;     (6 'ablog-highlight-face))))

  ;; Highlight dates which are clearly in the future (>=2021, maybe wrong timestamps?)
  (highlight-regexp "['\"]202[1-9]-[[:digit:]][[:digit:]]-[[:digit:]][[:digit:]]['\"]" 'ablog-error-face)
  (highlight-regexp "['\"]20[3456789][[:digit:]]-[[:digit:]][[:digit:]]-[[:digit:]][[:digit:]]['\"]" 'ablog-error-face)
  (highlight-regexp "['\"]2[123456789][[:digit:]][[:digit:]]-[[:digit:]][[:digit:]]-[[:digit:]][[:digit:]]['\"]" 'ablog-error-face)
  (highlight-regexp "['\"][13456789][[:digit:]][[:digit:]][[:digit:]]-[[:digit:]][[:digit:]]-[[:digit:]][[:digit:]]['\"]" 'ablog-error-face)

  ;; Highlight times which are out of normal working hours (maybe wrong timestamps?)
  (highlight-regexp " 0[01234567][[:digit:]]:[[:digit:]][[:digit:]]:[[:digit:]][[:digit:]]['\"]" 'ablog-error-face)
  (highlight-regexp " 2[01234]:[[:digit:]][[:digit:]]:[[:digit:]][[:digit:]]['\"]" 'ablog-error-face)

  ;; Highlight extra regexps.
  (highlight-regexp "Web Central build number: [0-9._]+" 'ablog-highlight-number-face)
  (highlight-regexp "Java version: [0-9._]+" 'ablog-highlight-number-face)
  (highlight-regexp "[a-z_]+_id" 'ablog-highlight-id-face)
  (highlight-regexp "status ?=" 'ablog-bold-face)
  (highlight-regexp "\.status" 'ablog-bold-face)
  (highlight-regexp "\\(= ?\\|, \\)[0-9.]*" 'ablog-highlight-number-face) ; '=', ' =' or ' ,' before numbers.
  (highlight-regexp "'[a-zA-Z0-9.,_@/: %()>-]*'" 'ablog-highlight-string-face)
  (highlight-regexp "NULL" 'ablog-highlight-null-face)
  (highlight-regexp "%[0-9][0-9]*" 'ablog-error-face)
                                        ; Problem with '@' in the metric name:
                                        ; the database query is using '%40'
                                        ; rather than '@'.
  (highlight-regexp "at .*invoke0.*" 'ablog-stack-trace-separator-face)
  (highlight-regexp ", database=\\[\\(security\\|schema\\|data\\)\\]" 'ablog-ignore-face))

(defvar ablog-hook nil
  "Hooks run when changing to ARCHIBUS-Log mode.")

(define-derived-mode ablog-mode text-mode "ABLog"
  "Major mode for viewing ARCHIBUS Log files.

\\{ablog-map}"
  :group 'ablog

  ;; Initialization.
  (setq-local cursor-type 'box)
  (setq-local mode-name "ARCHIBUS-Log")
  (read-only-mode 1)
  (use-local-map ablog-map)
  (setq-local scroll-margin 6)

  ;; Anzu setup.
  (when (featurep 'anzu)
    (setq-local anzu-search-threshold 1000))

  ;; Highlighting fields.
  (ablog-highlight-fields)

  ;; Automatic modes.
  (when (featurep 'hl-line)
    (hl-line-mode))

  (when (featurep 'auto-highlight-symbol)
    (add-to-list 'ahs-modes 'ablog)
    (auto-highlight-symbol-mode))

  ;; Run hooks.
  (run-hooks 'ablog-hook)

  ;; Display separator line.
  ;; (ablog-display-separator-line)

  (ablog-display-count-errors))

;;;###autoload
(add-to-list 'auto-mode-alist '("archibus\\.log\\'" . ablog-mode))

(defconst ablog-idle-interval 3
  "Number of seconds to wait before inserting separator.")

(defun ablog-display-separator-line ()
  "Separate blocks of log lines with a horizontal line."
  (interactive)
  (message "Adding separator lines... (This can take a while)")
  (save-excursion
    (goto-char (point-min))
    (let ((last nil) ov)
      (while (re-search-forward "[0-9]\\{4\\}-[01][1-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9]" nil t)
        (when last
          (let ((time-diff (- (float-time (date-to-time (match-string 0)))
                              (float-time (date-to-time last)))))
            (when (> time-diff ablog-idle-interval)
              (setq ov (make-overlay (line-beginning-position) (line-end-position)))
              (overlay-put ov 'face 'ablog-separator-face))))
        (setq last (match-string 0)))))
  (message "Adding separator lines... Done"))

(defun ablog-error-navigation (direction)
  "Navigate to the previous or next error based on DIRECTION (1 for next, -1 for previous)."
  (let ((case-fold-search nil))
    (if (re-search-forward ablog-error-regexp nil t direction)
        (progn
          (narrow-to-region (point-min) (line-end-position))
          (let ((current-count (ablog-count-errors)))
            (widen)
            (message "%d of %d errors" current-count (ablog-count-errors))))
      (message (if (= direction 1) "No more errors" "No previous errors")))))

(defun ablog-previous-error ()
  "Go to the previous error."
  (interactive)
  (beginning-of-line)
  (ablog-error-navigation -1))

(defun ablog-next-error ()
  "Go to the next error."
  (interactive)
  (ablog-error-navigation 1))

(defun ablog-previous-read-or-change ()
  "Go to line of previous SQL statement."
  (interactive)
  (move-beginning-of-line nil)
  (let ((case-fold-search nil))
    (search-backward-regexp ablog-sql-read-or-change-regexp)
    (search-forward-regexp ablog-sql-read-or-change-regexp))
                                        ; Go to the end of the searched pattern.
  )

(defun ablog-next-read-or-change ()
  "Go to line of next SQL statement."
  (interactive)
  (search-forward-regexp ablog-sql-read-or-change-regexp))

(defun ablog-previous-read ()
  "Go to line of previous SELECT SQL statement."
  (interactive)
  (move-beginning-of-line nil)
  (search-backward-regexp ablog-sql-read-regexp)
  (search-forward-regexp ablog-sql-read-regexp)
                                        ; Go to the end of the searched pattern.
  )

(defun ablog-next-read ()
  "Go to line of next SELECT SQL statement."
  (interactive)
  (search-forward-regexp ablog-sql-read-regexp))

(defun ablog-previous-change ()
  "Go to line of previous INSERT, UPDATE, DELETE or ALTER SQL or ... statement."
  (interactive)
  (move-beginning-of-line nil)
  (search-backward-regexp ablog-sql-change-regexp)
  (search-forward-regexp ablog-sql-change-regexp)
                                        ; Go to the end of the searched pattern.
  )

(defun ablog-next-change ()
  "Go to line of next INSERT, UPDATE, DELETE or ALTER SQL or ... statement."
  (interactive)
  (search-forward-regexp ablog-sql-change-regexp))

(defun ablog-previous-highlighted-class ()
  "Go to line of previous highlighted class."
  (interactive)
  (move-beginning-of-line nil)
  (search-backward-regexp (concat "\\[" (regexp-opt ablog-highlighted-class-names 'paren) "\\]")))

(defun ablog-next-highlighted-class ()
  "Go to line of next highlighted class."
  (interactive)
  (move-beginning-of-line nil)
  (forward-line 1)
  (search-forward-regexp (concat "\\[" (regexp-opt ablog-highlighted-class-names 'paren) "\\]")))

;;; Extra: ---------------------------------------------------------------------

(defun ablog-move-beginning-of-line ()
  "Move point to the beginning..."
  (interactive)
  (move-beginning-of-line nil)
  (search-forward "] - ["))

;; XXX See https://www.reddit.com/r/emacs/comments/4rif8d/emacs_lisp_listnonmatchinglines/?

(defun ablog-hide-lines-not-matching-sql (beg end)
  "When called with no active region, quiet the whole buffer instead.
Hide messages from ignored classes from POINT?  Wished from point XXX.
flush-lines. Should work on a region."
  (interactive "r")
  ;; (if (use-region-p) ...
  ;; (hide-lines-matching (regexp-opt ablog-ignored-class-names 'paren))
  ;; (hide-lines-matching "DataSourceDefLoader")
  ;; (hide-lines-matching "SecurityControllerTemplate")
  ;; (hide-lines-matching "RenderingFilter")
  (hide-lines-not-matching "DbConnectionImpl")
  (hide-lines-matching " - \\[SET CONCAT_NULL_YIELDS_NULL OFF")
  (hide-lines-matching " - \\[Updated: -1 records")
  (hide-lines-matching " - \\[\\*\\*\\*COMMIT\\*\\*\\*"))

(defun org-copy-visible (beg end)
  "Copy the visible parts of the region."
  (interactive "r")
  (let ((result ""))
    (while (/= beg end)
      (when (get-char-property beg 'invisible)
	    (setq beg (next-single-char-property-change beg 'invisible nil end)))
      (let ((next (next-single-char-property-change beg 'invisible nil end)))
	    (setq result (concat result (buffer-substring beg next)))
	    (setq beg next)))
    (kill-new result)))

(defun ablog-hide-lines-not-matching-sql-writes (beg end)
  "When called with no active region, strongly quiet the whole buffer instead.
Hide SELECT.  Use `flush-lines' or `hide-lines-matching' XXX???  We could not
edit a log file which is still in use.  So, hide is preferred..."
  (interactive "r")
  (ablog-hide-lines-not-matching-sql beg end)
  (hide-lines-matching "DbConnectionImpl\\] - \\[ ?SELECT"))

(defun ablog-show-all-lines ()
  "Show all lines hidden."
  (interactive)
  (hide-lines-show-all))

(defun ablog-show-error ()
  "XXX Error with keep-lines as archibus.log is read-only XXX"
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (keep-lines "^\\(\\[ERROR\\]\\|	at \\|	...\\|Caused by: \\)")))

(defun ablog-count-errors ()
  "Return the number of [ERROR]."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (count-matches "\\[ERROR\\]")))

(defun ablog-display-count-errors ()
  "Display the number of [ERROR]."
  (interactive)
  (message "%d [ERROR] found" (ablog-count-errors))
  (sleep-for 0 500))

(defun ablog-delete-leading-output-columns ()
  "Delete \"[PRIOR][Date Time][Class] - \" prefix in each line of the buffer. XXX"
  (interactive)
  (save-excursion
    (while (re-search-forward "^\\(\\[[A-Z ]*\\]\\[2017-05-31 11:52:01,093\\]\\[[[:alnum:]]*\\] - \\)" nil t)
      (replace-match ""))))

(defun ablog-kill-ring-save-sql-command ()
  "Save the current code block as if killed, but don't kill it."
  (interactive)
  (save-excursion
    (let ((beg (progn (beginning-of-line)
                      (search-forward "[")
                      (forward-char 1)
                      (search-forward "[")
                      (forward-char 1)
                      (search-forward "[")
                      (forward-char 1)
                      (search-forward "[")
                      (point)))
          (end (progn (end-of-line)
                      (search-backward ", database=[data]]") ; For ARCHIBUS 23+.
                      (point))))
      (copy-region-as-kill beg end)
      (message "Copied the current SQL command"))))

(define-key global-map (kbd "C-c w") #'ablog-kill-ring-save-sql-command)
(define-key global-map (kbd "H-w")   #'ablog-kill-ring-save-sql-command)
(define-key global-map (kbd "M-²")   #'ablog-kill-ring-save-sql-command)

(provide 'ablog)

;;; archibus-log.el ends here
