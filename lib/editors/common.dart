import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:function_types/function_types.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notium/core/note.dart';
import 'package:notium/core/notes_folder_fs.dart';
import 'package:notium/error_reporting.dart';
import 'package:notium/utils.dart';

export 'package:notium/editors/scaffold.dart';

typedef NoteCallback = void Function(Note);

abstract class Editor {
  NoteCallback get noteDeletionSelected;
  NoteCallback get exitEditorSelected;
  NoteCallback get renameNoteSelected;
  NoteCallback get moveNoteToFolderSelected;
  NoteCallback get discardChangesSelected;
}

abstract class EditorState with ChangeNotifier {
  Note getNote();
  Future<void> addImage(File file);

  bool get noteModified;
}

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Editor editor;
  final EditorState editorState;
  final bool noteModified;
  final IconButton extraButton;
  final bool allowEdits;
  final Func0<void> onEditingModeChange;

  EditorAppBar({
    Key key,
    @required this.editor,
    @required this.editorState,
    @required this.noteModified,
    @required this.allowEdits,
    @required this.onEditingModeChange,
    this.extraButton,
  })  : preferredSize = const Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        key: const ValueKey("NewEntry"),
        icon: Icon(noteModified ? Icons.check : Icons.close),
        onPressed: () {
          editor.exitEditorSelected(editorState.getNote());
        },
      ),
      actions: <Widget>[
        if (extraButton != null) extraButton,
        IconButton(
          icon: allowEdits
              ? const Icon(Icons.remove_red_eye)
              : const Icon(Icons.edit),
          onPressed: onEditingModeChange,
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            var note = editorState.getNote();
            editor.noteDeletionSelected(note);
          },
        ),
      ],
    );
  }
}

class EditorBottomBar extends StatelessWidget {
  final Editor editor;
  final EditorState editorState;
  final NotesFolderFS parentFolder;
  final bool allowEdits;
  final bool zenMode;
  final Func0<void> onZenModeChanged;
  final bool metaDataEditable;

  EditorBottomBar({
    @required this.editor,
    @required this.editorState,
    @required this.parentFolder,
    @required this.allowEdits,
    @required this.zenMode,
    @required this.onZenModeChanged,
    @required this.metaDataEditable,
  });

  @override
  Widget build(BuildContext context) {
    var addIcon = IconButton(
      icon: const Icon(Icons.attach_file),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (c) => _buildAddBottomSheet(c, editor, editorState),
          elevation: 0,
        );
      },
    );

    var menuIcon = IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (c) => _buildBottomMenuSheet(
            c,
            editor,
            editorState,
            zenMode,
            onZenModeChanged,
            metaDataEditable,
          ),
          elevation: 0,
        );
      },
    );

    return Container(
      color: Theme.of(context).bottomAppBarColor,
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Visibility(
              child: addIcon,
              visible: allowEdits,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              maintainInteractivity: false,
            ),
            Expanded(
              child: FlatButton.icon(
                icon: const Icon(Icons.folder),
                label: Text(parentFolder.publicName),
                onPressed: () {
                  var note = editorState.getNote();
                  editor.moveNoteToFolderSelected(note);
                },
              ),
            ),
            menuIcon,
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
    );
  }
}

Widget _buildAddBottomSheet(
  BuildContext context,
  Editor editor,
  EditorState editorState,
) {
  return Container(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.camera),
          title: Text(tr('editors.common.takePhoto')),
          onTap: () async {
            try {
              var image = await ImagePicker().getImage(
                source: ImageSource.camera,
              );

              if (image != null) {
                await editorState.addImage(File(image.path));
              }
            } catch (e) {
              reportError(e, StackTrace.current);
            }
            Navigator.of(context).pop();
          },
        ),
        ListTile(
          leading: const Icon(Icons.image),
          title: Text(tr('editors.common.addImage')),
          onTap: () async {
            try {
              var image = await ImagePicker().getImage(
                source: ImageSource.gallery,
              );

              if (image != null) {
                await editorState.addImage(File(image.path));
              }
            } catch (e) {
              if (e is PlatformException && e.code == "photo_access_denied") {
                Navigator.of(context).pop();
                return;
              }
              reportError(e, StackTrace.current);
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}

Widget _buildBottomMenuSheet(
  BuildContext context,
  Editor editor,
  EditorState editorState,
  bool zenModeEnabled,
  Func0<void> zenModeChanged,
  bool metaDataEditable,
) {
  return Container(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.undo),
          title: Text(tr('editors.common.discard')),
          onTap: () {
            var note = editorState.getNote();
            Navigator.of(context).pop();

            editor.discardChangesSelected(note);
          },
          enabled: editorState.noteModified,
        ),
        ListTile(
          leading: const Icon(Icons.share),
          title: Text(tr('editors.common.share')),
          onTap: () {
            var note = editorState.getNote();
            Navigator.of(context).pop();

            shareNote(note);
          },
        ),
      ],
    ),
  );
}
