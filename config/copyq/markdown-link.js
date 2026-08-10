function markdownLinkCollapseText(value)
{
  return str(value).replace(/\s+/g, ' ').trim();
}

function markdownLinkFirstUri(value)
{
  var lines = str(value).split(/\r?\n/);
  for (var i = 0; i < lines.length; ++i) {
    var line = lines[i].trim();
    if (line && line.charAt(0) !== '#')
      return line;
  }
  return '';
}

function markdownLinkLooksLikeTarget(value)
{
  var text = markdownLinkCollapseText(value);
  return /^[a-z][a-z0-9+.-]*:\/\//i.test(text)
    || /^(mailto|file):/i.test(text)
    || /^www\./i.test(text)
    || /^(~\/|\/|\.\.?\/)/.test(text);
}

function markdownLinkEncodeComponent(value)
{
  return encodeURIComponent(value).replace(/[!'()*]/g, function(character) {
    return '%' + character.charCodeAt(0).toString(16).toUpperCase();
  });
}

function markdownLinkFileUri(path)
{
  var absolutePath = path;
  if (/^~\//.test(absolutePath))
    absolutePath = Dir().homePath() + absolutePath.substring(1);

  var parts = absolutePath.split('/');
  for (var i = 0; i < parts.length; ++i)
    parts[i] = markdownLinkEncodeComponent(parts[i]);
  return 'file://' + parts.join('/');
}

function markdownLinkNormalizeTarget(value)
{
  var target = markdownLinkCollapseText(value);
  if (/^www\./i.test(target))
    target = 'https://' + target;
  else if (/^(~\/|\/)/.test(target))
    target = markdownLinkFileUri(target);

  return target
    .replace(/\s/g, '%20')
    .replace(/\\/g, '%5C')
    .replace(/</g, '%3C')
    .replace(/>/g, '%3E')
    .replace(/"/g, '%22')
    .replace(/\(/g, '%28')
    .replace(/\)/g, '%29');
}

function markdownLinkEscapeLabel(value)
{
  return markdownLinkCollapseText(value)
    .replace(/\\/g, '\\\\')
    .replace(/\[/g, '\\[')
    .replace(/\]/g, '\\]');
}

function markdownLinkFormat(label, target)
{
  var escapedLabel = markdownLinkEscapeLabel(label);
  var normalizedTarget = markdownLinkNormalizeTarget(target);
  if (!escapedLabel || !normalizedTarget)
    return '';
  return '[' + escapedLabel + '](' + normalizedTarget + ')';
}

function markdownLinkItem(row)
{
  var text = markdownLinkCollapseText(read(mimeText, row));
  var uri = markdownLinkFirstUri(read(mimeUriList, row));
  return {
    text: text || uri,
    target: uri || text,
    isTarget: !!uri || markdownLinkLooksLikeTarget(text),
  };
}

function pasteMarkdownLink()
{
  var clipboardTab = str(config('clipboard_tab'));
  if (clipboardTab)
    tab(clipboardTab);

  if (size() < 2) {
    popup('Markdown Link', 'Copy a link/path and its label first.');
    return;
  }

  var newest = markdownLinkItem(0);
  var previous = markdownLinkItem(1);
  var label = newest.text;
  var target = previous.target;

  if (newest.isTarget && !previous.isTarget) {
    label = previous.text;
    target = newest.target;
  } else if (!newest.isTarget && previous.isTarget) {
    label = newest.text;
    target = previous.target;
  }

  var markdown = markdownLinkFormat(label, target);
  if (!markdown) {
    popup('Markdown Link', 'The two newest items need non-empty text and link data.');
    return;
  }

  copy(markdown);
  paste();
}
