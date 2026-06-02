import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/asset.dart';
import '../../data/models/asset_folder.dart';
import 'asset_provider.dart';

class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(selectedFolderProvider);
    final folders = ref.watch(childFolderListProvider).valueOrNull ?? [];
    final assets = ref.watch(filteredAssetListProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(current?.name ?? 'Assets'),
        leading: current == null ? null : IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => ref.read(selectedFolderProvider.notifier).state = null),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: FloatingActionButton(onPressed: () => _showAddOptions(context, ref), backgroundColor: AppTheme.primary, foregroundColor: Colors.white, child: const Icon(Icons.add_rounded)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          if (folders.isEmpty && assets.isEmpty) const _EmptyAssets(),
          ...folders.map((f) => _FolderTile(folder: f)),
          ...assets.map((a) => _AssetTile(asset: a)),
        ],
      ),
    );
  }
}

class _EmptyAssets extends StatelessWidget { 
  const _EmptyAssets(); 
  @override Widget build(BuildContext context)=>Center(
    child:Padding(padding:const EdgeInsets.only(top:90), 
      child:Column(children:[Icon(
        Icons.folder_open_rounded, 
        size:56, 
        color:Colors.grey.shade400
      ), 
      const SizedBox(height:12), 
      Text('No files or folders here yet', style:TextStyle(color:Colors.grey.shade600))
      ])
    )
  ); 
}

class _FolderTile extends ConsumerWidget { 
  final AssetFolder folder; 
  const _FolderTile({required this.folder}); 
  @override Widget build(BuildContext context, WidgetRef ref)=>Card(
    child:ListTile(
      leading:const Text('📁', style:TextStyle(fontSize:28)), 
      title:Text(folder.name), 
      subtitle:folder.description==null?null:Text(folder.description!), 
      trailing:const Icon(Icons.chevron_right_rounded), 
      onTap:()=>ref.read(selectedFolderProvider.notifier).state=folder
    )
  ); 
}
class _AssetTile extends ConsumerWidget { 
  final Asset asset; 
  const _AssetTile({
    required this.asset
  }); 
  
  @override Widget build(BuildContext context, WidgetRef ref)=>Card(
    child:ListTile(
      leading:Icon(_icon(asset), 
      color:AppTheme.primary), 
      title:Text(asset.title), 
      subtitle:Text(asset.filePath?.split('/').last ?? asset.type), 
      onTap:()=>_open(asset), 
      trailing:PopupMenuButton<String>(onSelected:(v) async { 
        if(v=='delete'){ 
          final ok=await _confirm(context, asset); 
          if(ok==true){ 
            final a=await ref.read(assetActionsProvider.future); 
            await a.deleteAsset(asset); 
          }
        } 
        else { _open(asset); }
      }, 

        itemBuilder:(_)=>const [
          PopupMenuItem(value:'open', child:Text('Open')), 
          PopupMenuItem(value:'delete', child:Text('Delete'))
        ]
      )
    )
  ); 
  
  IconData _icon(Asset a){ 
    final e=(a.filePath??a.title).toLowerCase(); 
    if(e.endsWith('.pdf')) return Icons.picture_as_pdf_rounded; 
    if(e.endsWith('.jpg')||e.endsWith('.jpeg')||e.endsWith('.png'))return Icons.image_rounded; 
    return Icons.description_rounded;
  } 
  
  Future<void> _open(Asset a) async { 
    if(a.filePath==null)return; 
    final uri=Uri.file(a.filePath!); 
    await launchUrl(uri, mode:LaunchMode.externalApplication); 
  } 
  
  Future<bool?> _confirm(BuildContext context, Asset a)=>showDialog<bool>(
    context:context, 
    builder:(_)=>AlertDialog(
      title:const Text('Delete file?'), 
      content:Text('Remove ${a.title}?'), 
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false), 
      child:const Text('Cancel')), 
      TextButton(onPressed:()=>Navigator.pop(context,true), 
      child:const Text('Delete', style:TextStyle(color:Colors.red))) ]
    )
  ); 
}

void _showAddOptions(BuildContext context, WidgetRef ref) { 
  showModalBottomSheet(context:context, builder:(_)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min, children:[ListTile(leading:const Icon(Icons.create_new_folder_outlined), title:const Text('Create Folder'), onTap:(){Navigator.pop(context); _showFolderDialog(context, ref);}), ListTile(leading:const Icon(Icons.upload_file_rounded), title:const Text('Upload File'), onTap:(){Navigator.pop(context); _uploadFile(context, ref);})]))); }

void _showFolderDialog(BuildContext context, WidgetRef ref) { 
  final name=TextEditingController(); 
  showDialog(context:context, builder:(dialog)=>AlertDialog(
    title:const Text('Create Folder'), 
    content:TextField(
      controller:name, 
      decoration:const InputDecoration(labelText:'Folder name'), 
      autofocus:true
    ), 
    actions:[TextButton(onPressed:()=>Navigator.pop(dialog), child:const Text('Cancel')), 
    FilledButton(onPressed:() async { 
      if(name.text.trim().isEmpty)return; 
      final current=ref.read(selectedFolderProvider); 
      final a=await ref.read(assetActionsProvider.future); 
      await a.addFolder(AssetFolder(id:const Uuid().v4(), name:name.text.trim(), icon:'other', parentId:current?.id, createdAt:DateTime.now().millisecondsSinceEpoch)); 
      if(dialog.mounted)Navigator.pop(dialog);
    }, 
    
    child:const Text('Create'))]
  )); 
}
Future<void> _uploadFile(BuildContext context, WidgetRef ref) async { 
  const group=XTypeGroup(label:'Files', 
    extensions:['jpg','jpeg','png','pdf','doc','docx','xls','xlsx','ppt','pptx','txt','csv']
  ); 
  final file=await openFile(acceptedTypeGroups:[group]); 
  if(file==null)return; 
  final current=ref.read(selectedFolderProvider); 
  final now=DateTime.now().millisecondsSinceEpoch; 
  final ext=file.name.split('.').last.toLowerCase(); 
  final a=await ref.read(assetActionsProvider.future); 
  await a.addAsset(Asset(id:const Uuid().v4(), folderId:current?.id ?? 'root', title:file.name, type:_type(ext), filePath:file.path, createdAt:now, updatedAt:now)); 
}

String _type(String ext){ 
  if(['jpg','jpeg','png'].contains(ext))return 'image'; 
  if(['pdf','doc','docx','txt','csv'].contains(ext))return 'document'; 
  return 'other'; 
}