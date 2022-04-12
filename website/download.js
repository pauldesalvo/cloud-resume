var link = document.createElement('a');
link.href = url;
link.download = 'paul_desalvo_resume.pdf';
link.dispatchEvent(new MouseEvent('click'));