export class PassError extends Error { }
export class AccessibilityRequiredError extends PassError { }
export class SavedWithoutCommit extends PassError { }
export class BusyError extends PassError { }
export class CancelledError extends PassError { }
export class PartialOperationError extends PassError { }
