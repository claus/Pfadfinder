/* 
AMF3 parsers, reads AMF3 encoded data
Copyright (C) 2010  Gabriel Mariani

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
uint8 - BYTE - readUnsignedByte - U8
int8 - CHAR - readByte
uint16 - USHORT - readUnsignedShort - U16
int16 - SHORT - readShort
uint32 - ULONG - readUnsignedInt - U32
int32 - LONG - readInt

readBoolean : moves position by 1
readByte : moves position by 1
readDouble : moves position by 8
readFloat : moves position by 4
readInt : moves position by 4
readMultiByte : Reads a multibyte string of specified length from the file stream, byte stream
readShort : moves position by 2
readUnsignedByte : moves position by 1
readUnsignedInt : moves position by 4
readUnsignedShort : moves position by 2
readUTF : reads based on assumed prefix of string length
readUTFBytes : moves specified amount
*/

package com.coursevector.amf {
	
	import flash.utils.ByteArray;
	import flash.utils.describeType;
	import flash.xml.XMLDocument;
	
	public class AMF3 {
		
		public const VERSION:String = "3.0.0";
		
		// AMF marker constants
		protected const UNDEFINED_TYPE:int = 0;
		protected const NULL_TYPE:int = 1;
		protected const FALSE_TYPE:int = 2;
		protected const TRUE_TYPE:int = 3;
		protected const INTEGER_TYPE:int = 4;
		protected const DOUBLE_TYPE:int = 5;
		protected const STRING_TYPE:int = 6;
		protected const XML_DOC_TYPE:int = 7;
		protected const DATE_TYPE:int = 8;
		protected const ARRAY_TYPE:int = 9;
		protected const OBJECT_TYPE:int = 10;
		protected const XML_TYPE:int = 11;
		protected const BYTE_ARRAY_TYPE:int = 12;
		protected const VECTOR_INT_TYPE:int = 13;
		protected const VECTOR_UINT_TYPE:int = 14;
		protected const VECTOR_DOUBLE_TYPE:int = 15;
		protected const VECTOR_OBJECT_TYPE:int = 16;
		protected const DIRECTORY_TYPE:int = 17;
		
		/**
		 * Internal use only.
		 * @exclude
		 */
		protected const UINT29_MASK:int = 0x1FFFFFFF; // 2^29 - 1 : 536 870 911
		
		/**
		 * The maximum value for an <code>int</code> that will avoid promotion to an
		 * ActionScript Number when sent via AMF 3 is 2<sup>28</sup> - 1, or <code>0x0FFFFFFF</code>.
		 */
		protected const INT28_MAX_VALUE:int = 268435455;
		
		/**
		 * The minimum value for an <code>int</code> that will avoid promotion to an
		 * ActionScript Number when sent via AMF 3 is -2<sup>28</sup> or <code>0xF0000000</code>.
		 */
		protected const INT28_MIN_VALUE:int = -268435456;
		
		protected const EMPTY_STRING:String = "";
		
		// Simplified implementation of the class alias registry 
		protected const CLASS_ALIAS_REGISTRY:Object = {	
			"DSK": "flex.messaging.messages.AcknowledgeMessageExt",
			"DSA": "flex.messaging.messages.AsyncMessageExt",
			"DSC": "flex.messaging.messages.CommandMessageExt"	
		};
		
		/**
		 * The raw binary data
		 */
		protected var _rawData:ByteArray;
		
		/**
		 * The decoded data
		 */
		protected var _data:*;
		
		protected var readStringCache:Array = new Array(); // Length 64
		protected var readObjectCache:Array = new Array(); // Length 64
		protected var readTraitsCache:Array = new Array(); // Length 10
		
		protected var writeStringCache:Array;
		protected var writeObjectCache:Array;
		protected var writeTraitsCache:Array;
		
		protected var flex:Object = {
			/*
			"AbstractMessage" : AbstractMessage,
			"AsyncMessage" : AsyncMessage,
			"AsyncMessageExt" : AsyncMessageExt,
			"AcknowledgeMessage" : AcknowledgeMessage,
			"AcknowledgeMessageExt" : AcknowledgeMessageExt,
			"CommandMessage" : CommandMessage,
			"CommandMessageExt" : CommandMessageExt,
			"ErrorMessage" : ErrorMessage,
			"ArrayCollection" : ArrayCollection,
			"ArrayList" : ArrayList,
			"ObjectProxy" : ObjectProxy,
			"ManagedObjectProxy" : ManagedObjectProxy,
			"SerializationProxy" : SerializationProxy
			*/
		};
		
		public function AMF3():void { }
		
		public function get data():* { return _data; }
		
		public function get rawData():ByteArray { return _rawData; }
		
		public function deserialize(data:ByteArray, doReset:Boolean = true):void {
			if (doReset) {
				reset();
			}
			
			_rawData = data;
			_data = readData(_rawData);
		}
		
		public function serialize(data:*):void {
			reset();
			
			_data = data;
			_rawData = new ByteArray();
			writeData(_rawData, data);
		}
		
		public function reset():void {
			readStringCache = new Array();
			readObjectCache = new Array();
			readTraitsCache = new Array();
			
			writeStringCache = null;
			writeObjectCache = null;
			writeTraitsCache = null;
		}
		
		public function readData(ba:ByteArray):* {
			var type:int = ba.readByte();
			switch(type) {
				case UNDEFINED_TYPE : return undefined;
				case NULL_TYPE : return null;
				case FALSE_TYPE : return false;
				case TRUE_TYPE : return true;
				case INTEGER_TYPE : return readInt(ba);
				case DOUBLE_TYPE : return readDouble(ba);
				case STRING_TYPE : return readString(ba);
				case XML_DOC_TYPE : return readXMLDoc(ba);
				case DATE_TYPE : return readDate(ba);
				case ARRAY_TYPE : return readArray(ba);
				case OBJECT_TYPE : return readObject(ba);
				case XML_TYPE : return readXML(ba);
				case BYTE_ARRAY_TYPE : return readByteArray(ba);
				case VECTOR_INT_TYPE : return readVectorInt(ba);
				case VECTOR_UINT_TYPE : return readVectorUInt(ba);
				case VECTOR_DOUBLE_TYPE : return readVectorDouble(ba);
				default: throw Error("AMF3::readData - Error : Undefined AMF3 type encountered '" + type + "'");
			}
		}
		
		/**
		 * Read and deserialize an integer
		 * 
		 * 0x04 -> integer type code, followed by up to 4 bytes of data.
		 *
		 * @return A int capable of holding an unsigned 29 bit integer.
		 */
		protected function readInt(ba:ByteArray):int {
			var result:int = readUInt29(ba);
			// Symmetric with writing an integer to fix sign bits for negative values...
			result = (result << 3) >> 3;
			return result;
		}
		
		/**
		 * AMF 3 represents smaller integers with fewer bytes using the most
		 * significant bit of each byte. The worst case uses 32-bits
		 * to represent a 29-bit number, which is what we would have
		 * done with no compression.
		 * <pre>
		 * 0x00000000 - 0x0000007F : 0xxxxxxx
		 * 0x00000080 - 0x00003FFF : 1xxxxxxx 0xxxxxxx
		 * 0x00004000 - 0x001FFFFF : 1xxxxxxx 1xxxxxxx 0xxxxxxx
		 * 0x00200000 - 0x3FFFFFFF : 1xxxxxxx 1xxxxxxx 1xxxxxxx xxxxxxxx
		 * 0x40000000 - 0xFFFFFFFF : throw range exception
		 * </pre>
		 *
		 * @return A int capable of holding an unsigned 29 bit integer.
		 */
		protected function readUInt29(ba:ByteArray):int {
			var result:int = 0;
			
			// Each byte must be treated as unsigned
			var b:int = ba.readUnsignedByte();
			
			if (b < 128) return b;
			
			result = (b & 0x7F) << 7;
			b = ba.readUnsignedByte();
			
			if (b < 128) return (result | b);
			
			result = (result | (b & 0x7F)) << 7;
			b = ba.readUnsignedByte();
			
			if (b < 128) return (result | b);
			
			result = (result | (b & 0x7F)) << 8;
			b = ba.readUnsignedByte();
			
			return (result | b);
		}
		
		protected function readDouble(ba:ByteArray):Number {
			return ba.readDouble();
		}
		
		public function readString(ba:ByteArray):String {
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) return getStringReference(ref>>1);
			
			// writeString() special cases the empty string
			// to avoid creating a reference.
			var len:int = ref >> 1;
			var str:String = "";
			if (len > 0) {
				str = ba.readUTFBytes(len);
				readStringCache.push(str);
			}
			return str;
		}
		
		protected function readXMLDoc(ba:ByteArray):XMLDocument {
			var ref:int = readUInt29(ba);
			if((ref & 1) == 0) return getObjectReference(ref >> 1) as XMLDocument;
			
			var xmldoc:XMLDocument = new XMLDocument(ba.readUTFBytes(ref >> 1));
			readObjectCache.push(xmldoc);
			return xmldoc;
		}
		
		protected function readDate(ba:ByteArray):Date {
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) return getObjectReference(ref >> 1) as Date;
			
			var d:Date = new Date(ba.readDouble());
			readObjectCache.push(d);
			return d;
		}
		
		protected function readArray(ba:ByteArray):Array {
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) return getObjectReference(ref >> 1) as Array;
			
			var arr:Array = new Array();
			readObjectCache.push(arr);
			
			// Associative values
			var strKey:String = readString(ba);
			while(strKey != "") {
				arr[strKey] = readData(ba);
				strKey = readString(ba);
			}
			
			// Strict values
			var l:int = (ref >> 1);
			for(var i:int = 0; i < l; i++) {
				arr[i] = readData(ba);
			}
			
			return arr;
		}
		
		/**
		 * A single AMF 3 type handles ActionScript Objects and custom user classes. The term 'traits' 
		 * is used to describe the defining characteristics of a class. In addition to 'anonymous' objects 
		 * and 'typed' objects, ActionScript 3.0 introduces two further traits to describe how objects are 
		 * serialized, namely 'dynamic' and 'externalizable'.
		 * 
		 * Anonymous : an instance of the actual ActionScript Object type or an instance of a Class without 
		 * a registered alias (that will be treated like an Object on deserialization)
		 * 
		 * Typed : an instance of a Class with a registered alias
		 * 
		 * Dynamic : an instance of a Class definition with the dynamic trait declared; public variable members 
		 * can be added and removed from instances dynamically at runtime
		 * 
		 * Externalizable : an instance of a Class that implements flash.utils.IExternalizable and completely 
		 * controls the serialization of its members (no property names are included in the trait information).
		 * 
		 * @param	ba
		 * @return
		 */
		public function readObject(ba:ByteArray):Object {
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) return getObjectReference(ref >> 1);
			
			// Read traits
			var traits:Object;
			if ((ref & 3) == 1) {
				traits = getTraitReference(ref >> 2);
			} else {
				var isExternalizable:Boolean = ((ref & 4) == 4);
				var isDynamic:Boolean = ((ref & 8) == 8);
				var className:String = readString(ba);
				
				var classMemberCount:int = (ref >> 4); /* uint29 */
				var classMembers:Array = new Array();
				for(var i:int = 0; i < classMemberCount; ++i) {
					classMembers.push(readString(ba));
				}
				
				traits = { type:className, members:classMembers, count:classMemberCount, externalizable:isExternalizable, dynamic:isDynamic };
				readTraitsCache.push(traits);
			}
			
			// Check for any registered class aliases 
			var aliasedClass:String = CLASS_ALIAS_REGISTRY[traits.type];
			if (aliasedClass != null) traits.type = aliasedClass;
			
			var obj:Object = new Object();
			
			//Add to references as circular references may search for this object
			readObjectCache.push(obj);
			
			if (traits.externalizable) {
				// Read Externalizable
				//try {
				if (traits.type.indexOf("flex.") == 0) {
					// Try to get a class
					var classParts:Array = traits.type.split(".");
					var unqualifiedClassName:String = classParts[(classParts.length - 1)];
					if (unqualifiedClassName && flex[unqualifiedClassName]) {
						var flexParser:Object = new flex[unqualifiedClassName]();
						obj = flexParser.readExternal(ba, this);
					} else {
						obj = readData(ba);
					}
				}
				/*} catch (e:Error) {
				throw Error("AMF3::readObject - Error : Unable to read externalizable data type '" + traits.type + "' | " + e);
				}*/
			} else {
				var l:int = traits.members.length;
				var key:String;
				
				for(var j:int = 0; j < l; ++j) {
					if(ba.readByte() == 119) trace("asdfasdf");
					ba.position--;
					
					var pos:uint = ba.position;
					if (pos == 275) trace('sdfd');
					var val:* = readData(ba);
					key = traits.members[j];
					obj[key] = val;
				}
				
				if(traits.dynamic) {
					key = readString(ba);
					while(key != "") {
						var value:* = readData(ba);
						obj[key] = value;
						key = readString(ba);
					}
				}
			}
			
			if(traits.type) obj.__className = traits.type;
			
			return obj;
		}
		
		protected function readXML(ba:ByteArray):XML {
			var ref:int = readUInt29(ba);
			if((ref & 1) == 0)  return getObjectReference(ref >> 1) as XML;
			
			var xml:XML = new XML(ba.readUTFBytes(ref >> 1));
			readObjectCache.push(xml);
			return xml;
		}
		
		protected function readByteArray(ba:ByteArray):ByteArray {
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) return getObjectReference(ref >> 1) as ByteArray;
			
			var l:int = (ref >> 1);
			var ba2:ByteArray = new ByteArray();
			ba.readBytes(ba2, 0, l);
			readObjectCache.push(ba2);
			return ba2;
		}
		
		protected function readVectorInt(ba:ByteArray):Array {
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) return getObjectReference(ref >> 1) as Array;
			
			var arr:Array = new Array();
			readObjectCache.push(arr);
			
			var isFixedLength:Boolean = (ba.readUnsignedByte() == 0);
			
			var l:int = (ref >> 1);
			for(var i:int = 0; i < l; i++) {
				arr[i] = ba.readInt();
			}
			
			return arr;
		}
		
		protected function readVectorUInt(ba:ByteArray):Array {
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) return getObjectReference(ref >> 1) as Array;
			
			var arr:Array = new Array();
			readObjectCache.push(arr);

			var isFixedLength:Boolean = (ba.readUnsignedByte() == 0);
			
			var l:int = (ref >> 1);
			for(var i:int = 0; i < l; i++) {
				arr[i] = ba.readUnsignedInt();
			}

			return arr;
		}
		
		protected function readVectorDouble(ba:ByteArray):Array {
			var ref:int = readUInt29(ba);
			if ((ref & 1) == 0) return getObjectReference(ref >> 1) as Array;
			
			var arr:Array = new Array();
			readObjectCache.push(arr);
			
			var isFixedLength:Boolean = (ba.readUnsignedByte() == 0);
			
			var l:int = (ref >> 1);
			for(var i:int = 0; i < l; i++) {
				arr[i] = ba.readDouble();
			}
			
			return arr;
		}
		
		public function writeData(ba:ByteArray, value:*):void {
			// Null
			if (value == null) {
				writeNull(ba);
				return;
			}
			
			// Undefined
			if (value == undefined) {
				writeUndefined(ba);
				return;
			}
			
			// Boolean
			if (value is Boolean) {
				writeBoolean(ba, value);
				return;
			}
			
			// Number
			if (value is Number) {
				writeInt(ba, value);
				return;
			}
			
			// String
			if (value is String) {
				ba.writeByte(STRING_TYPE);
				writeString(ba, value);
				return;
			}
			
			// XML Document
			if (value is XMLDocument) {
				writeXMLDoc(ba, value);
				return;
			}
			
			// Date
			if (value is Date) {
				writeDate(ba, value);
				return;
			}
			
			// Array
			if (value is Array) {
				writeArray(ba, value);
				return;
			}
			
			// Object moved to bottom so it can be a catch-all for custom classes
			
			// XML
			if (value is XML) {
				writeXML(ba, value);
				return;
			}
			
			// Byte Array
			if (value is ByteArray) {
				writeByteArray(ba, value);
				return;
			}
			
			// Object
			if (value is Object) {
				writeObject(ba, value);
				return;
			}
		}
		
		/**
		 * The undefined type is represented by the undefined type marker. No further information is encoded for 
		 * this value.
		 * 
		 * undefined-type = undefined-marker
		 * 
		 * Note that endpoints other than the AVM may not have the concept of undefined and may choose to represent 
		 * undefined as null.
		 * 
		 * @param	ba
		 */
		protected function writeUndefined(ba:ByteArray):void {
			ba.writeByte(UNDEFINED_TYPE);
		}
		
		/**
		 * The null type is represented by the null type marker. No further information is encoded for this value.
		 * 
		 * null-type = null-marker
		 * 
		 * @param	ba
		 */
		protected function writeNull(ba:ByteArray):void {
			ba.writeByte(NULL_TYPE);
		}
		
		/**
		 * The false type is represented by the false type marker and is used to encode a Boolean value of false. 
		 * Note that in ActionScript 3.0 the concept of a primitive and Object form of Boolean does not exist. 
		 * No further information is encoded for this value.
		 * 
		 * false-type = false-marker
		 * 
		 * The true type is represented by the true type marker and is used to encode a Boolean value of true. 
		 * Note that in ActionScript 3.0 the concept of a primitive and Object form of Boolean does not exist. 
		 * No further information is encoded for this value.
		 * 
		 * true-type = true-marker
		 * 
		 * @param	ba
		 * @param	value
		 */
		protected function writeBoolean(ba:ByteArray, value:Boolean):void {
			ba.writeByte(value ? TRUE_TYPE : FALSE_TYPE);
		}
		
		protected function writeInt(ba:ByteArray, value:Number):void {
			if (value >= INT28_MIN_VALUE && value <= INT28_MAX_VALUE && (value % 1 == 0)) {
				// We have to be careful when the MSB is set, as (value >> 3) will sign extend.
				// We know there are only 29-bits of precision, so truncate. This requires
				// similar care when reading an integer.
				//value = ((value >> 3) & UINT29_MASK);
				value &= UINT29_MASK; // Mask is 2^29 - 1
				ba.writeByte(INTEGER_TYPE);
				writeUInt29(ba, value);
			} else {
				// Promote large int to a double
				writeDouble(ba, value);
			}
		}
		
		/**
		 * In AMF 3 integers are serialized using a variable length unsigned 29-bit integer. The ActionScript 3.0 
		 * integer types - a signed 'int' type and an unsigned 'uint' type - are also represented using 29-bits in 
		 * AVM+. If the value of an unsigned integer (uint) is greater or equal to 2^29 or if the value of a signed 
		 * integer (int) is greater than or equal to 2^28 then it will be represented by AVM+ as a double and thus 
		 * serialized in using the AMF 3 double type.
		 * 
		 * integer-type = integer-marker U29
		 * 
		 * @param	ba
		 * @param	value
		 */
		protected function writeUInt29(ba:ByteArray, value:int):void {
			// Represent smaller integers with fewer bytes using the most
			// significant bit of each byte. The worst case uses 32-bits
			// to represent a 29-bit number, which is what we would have
			// done with no compression.
			
			// 0x00000000 - 0x0000007F : 0xxxxxxx
			// 0x00000080 - 0x00003FFF : 1xxxxxxx 0xxxxxxx
			// 0x00004000 - 0x001FFFFF : 1xxxxxxx 1xxxxxxx 0xxxxxxx
			// 0x00200000 - 0x3FFFFFFF : 1xxxxxxx 1xxxxxxx 1xxxxxxx xxxxxxxx
			// 0x40000000 - 0xFFFFFFFF : throw range exception
			
			if (value < 0x80) { // Less than 128 - 0x00000000 - 0x0000007F : 0xxxxxxx
				ba.writeByte(value);
			} else if (value < 0x4000) { // Less than 16,384 - 0x00000080 - 0x00003FFF : 1xxxxxxx 0xxxxxxx
				ba.writeByte(value >> 7 & 0x7F | 0x80);
				ba.writeByte(value & 0x7F);
			} else if (value < 0x200000) { // Less than 2,097,152 - 0x00004000 - 0x001FFFFF : 1xxxxxxx 1xxxxxxx 0xxxxxxx
				ba.writeByte(value >> 14 & 0x7F | 0x80);
				ba.writeByte(value >> 7 & 0x7F | 0x80);
				ba.writeByte(value & 0x7F);
			} else if (value < 0x40000000) { // 0x00200000 - 0x3FFFFFFF : 1xxxxxxx 1xxxxxxx 1xxxxxxx xxxxxxxx
				ba.writeByte(value >> 22 & 0x7F | 0x80);
				ba.writeByte(value >> 15 & 0x7F | 0x80);
				ba.writeByte(value >> 8 & 0x7F | 0x80);
				ba.writeByte(value & 0xFF);
			} else { // 0x40000000 - 0xFFFFFFFF : throw range exception
				throw new Error("Integer out of range: " + value);
			}
		}
		
		/**
		 * The AMF 3 double type is encoded in the same manner as the AMF 0 Number type. This type is used to 
		 * encode an ActionScript Number or an ActionScript int of value greater than or equal to 2^28 or an 
		 * ActionScript uint of value greater than or equal to 2^29. The encoded value is is always an 8 byte 
		 * IEEE-754 double precision floating point value in network byte order (sign bit in low memory).
		 * 
		 * double-type = double-marker DOUBLE
		 * 
		 * @param	ba
		 * @param	value
		 */
		protected function writeDouble(ba:ByteArray, value:Number):void {
			ba.writeByte(DOUBLE_TYPE);
			ba.writeDouble(value);
		}
		
		/**
		 * ActionScript String values are represented using a single string type in AMF 3 - the concept of string 
		 * and long string types from AMF 0 is not used.
		 * 
		 * Strings can be sent as a reference to a previously occurring String by using an index to the implicit 
		 * string reference table.
		 * 
		 * Strings are encoding using UTF-8 - however the header may either describe a string literal or a string 
		 * reference.
		 * 
		 * The empty String is never sent by reference.
		 * 
		 * string-type = string-marker UTF-8-vr
		 * 
		 * @param	ba
		 * @param	value
		 */
		public function writeString(ba:ByteArray, value:String, writeRef:Boolean = true):void {
			// Note: Type is not encoded here becuase writeString is used for multiple types
			if(value == "") {
				//Write 0x01 to specify the empty string
				ba.writeByte(0x01);
			} else {
				if (writeRef) {
					if(setStringReference(ba, value)) {
						writeUInt29(ba, (value.length << 1) | 1);
						ba.writeUTFBytes(value);
					}
				} else {
					writeUInt29(ba, (value.length << 1) | 1);
					ba.writeUTFBytes(value);
				}
			}
		}
		
		/**
		 * ActionScript 3.0 introduced a new XML type however the legacy XMLDocument type is retained in 
		 * the language as flash.xml.XMLDocument. Similar to AMF 0, the structure of an XMLDocument needs to be 
		 * flattened into a string representation for serialization. As with other strings in AMF, the content is 
		 * encoded in UTF-8.
		 * 
		 * XMLDocuments can be sent as a reference to a previously occurring XMLDocument instance by using an index 
		 * to the implicit object reference table.
		 * 
		 * U29X-value = U29. The first (low) bit is a flag with value 1. The remaining 1 to 28 significant bits are 
		 * used to encode the byte-length of the UTF-8 encoded representation of the XML or XMLDocument.
		 * 
		 * xml-doc-type = xml-doc-marker (U29O-ref | (U29X-value *(UTF8-char)))
		 * 
		 * Note that this encoding imposes some theoretical limits on the use of XMLDocument. The byte-length of each 
		 * UTF-8 encoded XMLDocument instance is limited to 2^28 - 1 bytes (approx 256 MB).
		 * 
		 * @param	ba
		 * @param	value
		 */
		protected function writeXMLDoc(ba:ByteArray, value:XMLDocument):void {
			ba.writeByte(XML_DOC_TYPE);
			
			if(setObjectReference(ba, value)) {
				var strXML:String = value.toString();
				strXML = strXML.replace(/^\s+|\s+$/g, ''); // Trim
				strXML = strXML.replace(/\>(\n|\r|\r\n| |\t)*\</g, "><"); // Strip whitespaces
				writeString(ba, strXML, false);
			}
		}
		
		/**
		 * In AMF 3 an ActionScript Date is serialized simply as the number of milliseconds elapsed since the epoch 
		 * of midnight, 1st Jan 1970 in the UTC time zone. Local time zone information is not sent.
		 * 
		 * Dates can be sent as a reference to a previously occurring Date instance by using an index to the implicit 
		 * object reference table.
		 * 
		 * U29D-value = U29 ; The first (low) bit is a flag with value 1. The remaining bits are not used.
		 * 
		 * date-time = DOUBLE ; A 64-bit integer value transported as a double.
		 * 
		 * date-type = date-marker (U29O-ref | (U29D-value date-time))
		 * 
		 * @param	ba
		 * @param	value
		 */
		protected function writeDate(ba:ByteArray, value:Date):void {
			ba.writeByte(DATE_TYPE);
			
			if(setObjectReference(ba, value)) {
				//Write out an invalid reference
				writeUInt29(ba, 1);
				//ba.writeByte(0x01); // Flag
				
				ba.writeDouble(value.time);
			}
		}
		
		/**
		 * ActionScript Arrays are described based on the nature of their indices, i.e. their type and how they are 
		 * positioned in the Array. The following table outlines the terms and their meaning:
		 * 
		 * strict - contains only ordinal (numeric) indices 
		 * dense - ordinal indices start at 0 and do not contain gaps between successive indices (that is, every index is defined from 0 for the length of the array)
		 * sparse - contains at least one gap between two indices
		 * associative - contains at least one non-ordinal (string) index (sometimes referred to as an ECMA Array)
		 * 
		 * AMF considers Arrays in two parts, the dense portion and the associative portion. The binary representation 
		 * of the associative portion consists of name/value pairs (potentially none) terminated by an empty string. 
		 * The binary representation of the dense portion is the size of the dense portion (potentially zero) followed 
		 * by an ordered list of values (potentially none). The order these are written in AMF is first the size of 
		 * the dense portion, a empty string terminated list of name/value pairs, followed by size values.
		 * 
		 * Arrays can be sent as a reference to a previously occurring Array by using an index to the implicit object 
		 * reference table.
		 * 
		 * U29A-value = U29 ; The first (low) bit is a flag with value 1. The remaining 1 to 28 significant bits are 
		 * used to encode the count of the dense portion of the Array
		 * 
		 * assoc-value = UTF-8-vr value-type
		 * 
		 * array-type = array-marker (U29O-ref | (U29A-value (UTF-8-empty | *(assoc-value) UTF-8-empty) *(value-type)))
		 * 
		 * @param	ba
		 * @param	value
		 */
		protected function writeArray(ba:ByteArray, value:Array):void {
			var arrNumeric:Array = new Array(); // holder to store the numeric keys
			var objString:Object = new Object(); // holder to store the string keys
			var l:uint = value.length; // get the total number of entries for the array
			var numElements:int = 0;
			var key:*;
			var i:int;
			var isSparse:Boolean = false;
			var isAssociative:Boolean = false;
			
			// Find the numeric and string key values
			var strLen:uint = 0;
			for (key in value) {
				numElements++;
				if (key is Number && key >= 0) { // make sure the keys are numeric
					arrNumeric[key] = value[key]; // The key is an index in an array
				} else {
					objString[key] = value[key]; // The key is a property of an object
					strLen++;
				}
			}
			
			// Spare arrays will have a different number of actual items but length reports different
			isSparse = Boolean(numElements < l);
			isAssociative = Boolean(strLen > 0);
			
			// Array tag
			ba.writeByte(ARRAY_TYPE); 
			
			if (setObjectReference(ba, value)) {
				// This is a mixed array
				if (isAssociative || isSparse) {
					// Dynamic object, no classname to write
					writeUInt29(ba, (0 << 1) | 1);
					
					for (key in value) {
						writeString(ba, key);
						writeData(ba, value[key]);
					}
					
					// Since this is a dynamic object, add closing tag
					writeString(ba, EMPTY_STRING);
				}
					
					// This is just an array
				else {
					var numLen:int = arrNumeric.length; 
					writeUInt29(ba, (numLen << 1) | 1);
					
					for (key in objString) {
						writeString(ba, key);
						writeData(ba, objString[key]);
					}
					
					// End start hash
					writeString(ba, EMPTY_STRING);
					
					for (i = 0; i < numLen; i++) {
						writeData(ba, arrNumeric[i]);
					}
				}
			}
		}
		
		/**
		 * A single AMF 3 type handles ActionScript Objects and custom user classes. The term 'traits' is used to describe 
		 * the defining characteristics of a class. In addition to 'anonymous' objects and 'typed' objects, ActionScript 3.0 
		 * introduces two further traits to describe how objects are serialized, namely 'dynamic' and 'externalizable'. The 
		 * following table outlines the terms and their meanings:
		 * 
		 * Anonymous - an instance of the actual ActionScript Object type or an instance of a Class without a registered alias 
		 * 				(that will be treated like an Object on deserialization)
		 * 
		 * Typed - an instance of a Class with a registered alias
		 * 
		 * Dynamic - an instance of a Class definition with the dynamic trait declared; public variable members can be added 
		 * 			 and removed from instances dynamically at runtime
		 * 
		 * Externalizable - an instance of a Class that implements flash.utils.IExternalizable and completely controls the 
		 * 					serialization of its members (no property names are included in the trait information).
		 * 
		 * In addition to these characteristics, an object's traits information may also include a set of public variable and 
		 * public read-writeable property names defined on a Class (i.e. public members that are not Functions). The order of 
		 * the member names is important as the member values that follow the traits information will be in the exact same order. 
		 * These members are considered sealed members as they are explicitly defined by the type.
		 * 
		 * If the type is dynamic, a further section may be included after the sealed members that lists dynamic members as 
		 * name / value pairs. One continues to read in dynamic members until a name that is the empty string is encountered.
		 * 
		 * Objects can be sent as a reference to a previously occurring Object by using an index to the implicit object reference 
		 * table. Further more, trait information can also be sent as a reference to a previously occurring set of traits by using 
		 * an index to the implicit traits reference table.
		 * 
		 * U29O-ref = U29 ; The first (low) bit is a flag (representing whether an instance follows) with value 0 to imply that 
		 * 					this is not an instance but a reference. The remaining 1 to 28 significant bits are used to encode 
		 * 					an object reference index (an integer).
		 * 
		 * U29O-traits-ref = U29 ; The first (low) bit is a flag with value 1. The second bit is a flag (representing whether a 
		 * 					trait reference follows) with value 0 to imply that this objects traits are being sent by reference. The remaining 1 
		 * 					to 27 significant bits are used to encode a trait reference index (an integer).
		 * 
		 * U29O-traits-ext = U29 ; The first (low) bit is a flag with value 1. The second bit is a flag with value 1. The third bit 
		 * 					is a flag with value 1. The remaining 1 to 26 significant bits are not significant (the traits member count would always be 0).
		 * 
		 * U29O-traits = U29 ; The first (low) bit is a flag with value 1. The second bit is a flag with value 1. The third bit is a 
		 * 					flag with value 0. The fourth bit is a flag specifying whether the type is dynamic. A value of 0 implies not dynamic, a value 
		 * 					of 1 implies dynamic. Dynamic types may have a set of name value pairs for dynamic members after the sealed member section. 
		 * 					The remaining 1 to 25 significant bits are used to encode the number of sealed traits member names that follow after the class 
		 * 					name (an integer).
		 * 
		 * class-name = UTF-8-vr ; use the empty string for anonymous classes
		 * 
		 * dynamic-member = UTF-8-vr value-type ; Another dynamic member follows until the string-type is the empty string
		 * 
		 * object-type = object-marker (U29O-ref | (U29O-traits-ext class-name *(U8)) | U29O-traits-ref | (U29O-traits class-name *(UTF-8-vr))) *(value-type) *(dynamic-member)))
		 * 
		 * @param	ba
		 * @param	value
		 */
		protected function writeObject(ba:ByteArray, value:Object):void {
			// Write the object tag
			ba.writeByte(OBJECT_TYPE); 
			
			// Write Traits
			if (setObjectReference(ba, value)) {
				var desc:XML = describeType(value);
				var traits:Object = {external:false, dynamic:false, count:0 };
				var v:XML;
				
				// Create Traits Object
				//traits.instance = value;
				
				var l:int = desc.implementsInterface.length();
				while (l--) {
					if (desc.implementsInterface[l].@type.toString() == "flash.utils::IExternalizable") {
						traits.external = true;
						break;
					}
				}
				
				if (!traits.external) {
					traits.dynamic = desc.@isDynamic.toString() == "true";
					// Dynamic types may have a set of name value pairs for dynamic members after the sealed member section. 
					// The remaining 1 to 25 significant bits are used to encode the number of sealed traits member names that follow after the class 
					// name (an integer).
					traits.count = desc.variable.length();
				}
				
				traits.className = desc.@name.toString();
				//
				
				// Write Traits
				if (setTraitReference(ba, traits)) {
					// Write trait flag
					writeUInt29(ba, 3 | (traits.external ? 4 : 0) | (traits.dynamic ? 8 : 0) | (traits.count << 4));
					
					// Write class name
					if(traits.className != "Object") {
						writeString(ba, traits.className);
					} else {
						writeString(ba, "");
					}
					
					if(!traits.external && traits.count > 0) {
						for each (v in desc.variable) {
							writeString(ba, v.@name);
						}
					}
				}
				
				// Should the propnames and values be written seperately?
				
				// Write Data
				if (traits.external) {
					value.writeExternal(ba);
				} else {
					//} else if (traits.count > 0) {
					// For some reason AS3 can't for..in loop over a class
					if(traits.className != "Object") {
						for each (v in desc.variable) {
							writeString(ba, v.@name.toString());
							writeData(ba, value[v.@name.toString()]);
						}
					} else {
						for (var v2:String in value) {
							writeString(ba, v2);
							writeData(ba, value[v2]);
						}
					}
				}
				
				// Write closing object tag
				if(traits.dynamic) ba.writeByte(0x01); 
			}
		}
		
		/**
		 * ActionScript 3.0 introduces a new XML type that supports E4X syntax. For serialization purposes 
		 * the XML type needs to be flattened into a string representation. As with other strings in AMF, 
		 * the content is encoded using UTF-8.
		 * 
		 * XML instances can be sent as a reference to a previously occurring XML instance by using an index 
		 * to the implicit object reference table.
		 * 
		 * xml-type = xml-marker (U29O-ref | (U29X-value *(UTF8-char)))
		 * 
		 * Note that this encoding imposes some theoretical limits on the use of XML. The byte-length of each 
		 * UTF-8 encoded XML instance is limited to 2^28 - 1 bytes (approx 256 MB).
		 * 
		 * @param	ba
		 * @param	value
		 */
		protected function writeXML(ba:ByteArray, value:XML):void {
			ba.writeByte(XML_TYPE);
			
			if(setObjectReference(ba, value)) {
				var strXML:String = value.toXMLString();
				strXML = strXML.replace(/^\s+|\s+$/g, ''); // Trim
				//strXML = strXML.replace(/\>(\n|\r|\r\n| |\t)*\</g, "><"); // Strip whitespaces, not done by native encoder
				writeString(ba, strXML, false);
			}
		}
		
		/**
		 * ActionScript 3.0 introduces a new type to hold an Array of bytes, namely ByteArray. AMF 3 serializes 
		 * this type using a variable length encoding 29-bit integer for the byte-length prefix followed by the 
		 * raw bytes of the ByteArray.
		 * 
		 * ByteArray instances can be sent as a reference to a previously occurring ByteArray instance by using 
		 * an index to the implicit object reference table.
		 * 
		 * U29B-value = U29 ; The first (low) bit is a flag with value 1. The remaining 1 to 28 significant bits 
		 * are used to encode the byte-length of the ByteArray.
		 * 
		 * bytearray-type = bytearray-marker (U29O-ref | U29B-value *(U8))
		 * 
		 * Note that this encoding imposes some theoretical limits on the use of ByteArray. The maximum byte-length 
		 * of each ByteArray instance is limited to 2^28 - 1 bytes (approx 256 MB).
		 * 
		 * @param	ba
		 * @param	value
		 */
		protected function writeByteArray(ba:ByteArray, value:ByteArray):void {
			ba.writeByte(BYTE_ARRAY_TYPE);
			
			if (setObjectReference(ba, value)) {
				writeUInt29(ba, (value.length << 1) | 1);
				ba.writeBytes(value);
			}
		}
		
		protected function getStringReference(ref:int):String {
			if (ref >= readStringCache.length) {
				throw Error("AMF3::getStringReference - Error : Undefined string reference '" + ref + "'");
				return null;
			}
			
			return readStringCache[ref];
		}
		
		protected function getTraitReference(ref:int):Object {
			if (ref >= readTraitsCache.length) {
				throw Error("AMF3::getTraitReference - Error : Undefined trait reference '" + ref + "'" + " " + readTraitsCache.length);
				return null;
			}
			
			return readTraitsCache[ref];
		}
		
		protected function getObjectReference(ref:int):Object {
			if (ref >= readObjectCache.length) {
				throw Error("AMF3::getObjectReference - Error : Undefined object reference '" + ref + "'");
				return null;
			}
			
			return readObjectCache[ref];
		}
		
		protected function setStringReference(ba:ByteArray, s:String):Boolean {
			var refNum:int;
			if (writeStringCache != null && (refNum = hasItem(writeStringCache, s)) != -1) {
				writeUInt29(ba, refNum << 1);
				return false;
			} else {
				if (writeStringCache == null) writeStringCache = new Array();
				if (writeStringCache.length < 64) writeStringCache.push(s);
				return true;
			}
		}
		
		protected function setObjectReference(ba:ByteArray, o:Object):Boolean {
			var refNum:int;
			if (writeObjectCache != null && (refNum = hasItem(writeObjectCache, o)) != -1) {
				writeUInt29(ba, refNum << 1);
				return false;
			} else {
				if (writeObjectCache == null) writeObjectCache = new Array();  
				if (writeObjectCache.length < 64) writeObjectCache.push(o);
				return true;
			}
		}
		
		protected function setTraitReference(ba:ByteArray, traits:Object):Boolean {
			var refNum:int;
			if (writeTraitsCache != null && (refNum = hasItem(writeTraitsCache, traits)) != -1) {
				writeUInt29(ba, (refNum << 2) | 1);
				return false;
			} else {
				if (writeTraitsCache == null) writeTraitsCache = new Array();
				if (writeTraitsCache.length < 10) writeTraitsCache.push(traits);
				return true;
			}
		}
		
		protected function hasItem(array:Array, item:*):int {
			var i:int = array.length;
			while (i--) {
				if(isSame(array[i], item)) return i;
			}
			return -1;
		}
		
		protected function isSame(item1:*, item2:*):Boolean {
			// If it's an object
			if(typeof item1 == "object" && typeof item2 == "object") {
				// If it's the same type of object
				if(Object(item1).constructor == Object(item2).constructor) {
					for (var i:String in item1) {
						if (typeof item1[i] == "object") {
							// Only return if they don't match
							if(!isSame(item1[i], item2[i])) return false;
						} else if (item1[i] != item2[i]) {
							return false;
						}
					}
					
					return true;
				} else {
					return false;
				}
			}
			
			// If it's a simple type
			return (item1 === item2);
		}
		
		/*public static function compare (obj1:Object, obj2:Object):Boolean {
		
		var b1:ByteArray = new ByteArray();
		var b2:ByteArray = new ByteArray();
		
		b1.writeObject(obj1);
		b2.writeObject(obj2);
		
		// compare the lengths first
		var size:uint = b1.length;
		if (b1.length == b2.length) {
		b1.position = 0;
		b2.position = 0;
		
		// then the bits
		while (b1.position < size) {
		var v1:int = b1.readByte();
		if (v1 != b2.readByte()) {
		return false;
		}
		}                            
		}
		
		
		if (b1.toString() == b2.toString()) {
		return true;
		}              
		
		return false;
		}*/
	}
}

import flash.utils.ByteArray;

class UUIDUtils {
	
	private static var UPPER_DIGITS:Array = [
		'0', '1', '2', '3', '4', '5', '6', '7',
		'8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
	];
	
	public static function fromByteArray(ba:ByteArray):String {
		if (ba != null && ba.length == 16) {
			var result:String = "";
			for (var i:int = 0; i < 16; i++) {
				if (i == 4 || i == 6 || i == 8 || i == 10) result += "-";
				
				result += UPPER_DIGITS[(ba[i] & 0xF0) >>> 4];
				result += UPPER_DIGITS[(ba[i] & 0x0F)];
			}
			return result;
		}
		
		return null;
	}
}

