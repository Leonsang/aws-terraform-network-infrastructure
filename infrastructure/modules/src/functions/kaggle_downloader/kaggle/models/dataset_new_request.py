#!/usr/bin/python
#
# Copyright 2024 Kaggle Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# coding: utf-8

import pprint
import re  # noqa: F401

import six

from kaggle.models.upload_file import UploadFile  # noqa: F401,E501


class DatasetNewRequest(object):
    """
    Attributes:
      project_types (dict): The key is attribute name
                            and the value is attribute type.
      attribute_map (dict): The key is attribute name
                            and the value is json key in definition.
    """
    project_types = {
        'title': 'str',
        'slug': 'str',
        'owner_slug': 'str',
        'license_name': 'str',
        'subtitle': 'str',
        'description': 'str',
        'files': 'list[UploadFile]',
        'is_private': 'bool',
        'convert_to_csv': 'bool',
        'category_ids': 'list[str]'
    }

    attribute_map = {
        'title': 'title',
        'slug': 'slug',
        'owner_slug': 'ownerSlug',
        'license_name': 'licenseName',
        'subtitle': 'subtitle',
        'description': 'description',
        'files': 'files',
        'is_private': 'isPrivate',
        'convert_to_csv': 'convertToCsv',
        'category_ids': 'categoryIds'
    }

    def __init__(self, title=None, slug=None, owner_slug=None, license_name='unknown', subtitle=None, description='', files=None, is_private=True, convert_to_csv=True, category_ids=None):  # noqa: E501

        self._title = None
        self._slug = None
        self._owner_slug = None
        self._license_name = None
        self._subtitle = None
        self._description = None
        self._files = None
        self._is_private = None
        self._convert_to_csv = None
        self._category_ids = None
        self.discriminator = None

        self.title = title
        if slug is not None:
            self.slug = slug
        if owner_slug is not None:
            self.owner_slug = owner_slug
        if license_name is not None:
            self.license_name = license_name
        if subtitle is not None:
            self.subtitle = subtitle
        if description is not None:
            self.description = description
        self.files = files
        if is_private is not None:
            self.is_private = is_private
        if convert_to_csv is not None:
            self.convert_to_csv = convert_to_csv
        if category_ids is not None:
            self.category_ids = category_ids

    @property
    def title(self):
        """Gets the title of this DatasetNewRequest.  # noqa: E501

        The title of the new dataset  # noqa: E501

        :return: The title of this DatasetNewRequest.  # noqa: E501
        :rtype: str
        """
        return self._title

    @title.setter
    def title(self, title):
        """Sets the title of this DatasetNewRequest.

        The title of the new dataset  # noqa: E501

        :param title: The title of this DatasetNewRequest.  # noqa: E501
        :type: str
        """
        if title is None:
            raise ValueError("Invalid value for `title`, must not be `None`")  # noqa: E501

        self._title = title

    @property
    def slug(self):
        """Gets the slug of this DatasetNewRequest.  # noqa: E501

        The slug that the dataset should be created with  # noqa: E501

        :return: The slug of this DatasetNewRequest.  # noqa: E501
        :rtype: str
        """
        return self._slug

    @slug.setter
    def slug(self, slug):
        """Sets the slug of this DatasetNewRequest.

        The slug that the dataset should be created with  # noqa: E501

        :param slug: The slug of this DatasetNewRequest.  # noqa: E501
        :type: str
        """

        self._slug = slug

    @property
    def owner_slug(self):
        """Gets the owner_slug of this DatasetNewRequest.  # noqa: E501

        The owner's username  # noqa: E501

        :return: The owner_slug of this DatasetNewRequest.  # noqa: E501
        :rtype: str
        """
        return self._owner_slug

    @owner_slug.setter
    def owner_slug(self, owner_slug):
        """Sets the owner_slug of this DatasetNewRequest.

        The owner's username  # noqa: E501

        :param owner_slug: The owner_slug of this DatasetNewRequest.  # noqa: E501
        :type: str
        """

        self._owner_slug = owner_slug

    @property
    def license_name(self):
        """Gets the license_name of this DatasetNewRequest.  # noqa: E501

        The license that should be associated with the dataset  # noqa: E501

        :return: The license_name of this DatasetNewRequest.  # noqa: E501
        :rtype: str
        """
        return self._license_name

    @license_name.setter
    def license_name(self, license_name):
        """Sets the license_name of this DatasetNewRequest.

        The license that should be associated with the dataset  # noqa: E501

        :param license_name: The license_name of this DatasetNewRequest.  # noqa: E501
        :type: str
        """
        allowed_values = ["CC0-1.0", "CC-BY-SA-4.0", "GPL-2.0", "ODbL-1.0", "CC-BY-NC-SA-4.0", "unknown", "DbCL-1.0", "CC-BY-SA-3.0", "copyright-authors", "other", "reddit-api", "world-bank", "CC-BY-4.0", "CC-BY-NC-4.0", "PDDL", "CC-BY-3.0", "CC-BY-3.0-IGO", "US-Government-Works", "CC-BY-NC-SA-3.0-IGO", "CDLA-Permissive-1.0", "CDLA-Sharing-1.0", "CC-BY-ND-4.0", "CC-BY-NC-ND-4.0", "ODC-BY-1.0", "LGPL-3.0", "AGPL-3.0", "FDL-1.3", "EU-ODP-Legal-Notice", "apache-2.0", "GPL-3.0"]  # noqa: E501
        if license_name not in allowed_values:
            raise ValueError(
                "Invalid value for `license_name` ({0}), must be one of {1}"  # noqa: E501
                .format(license_name, allowed_values)
            )
        else:
            license_name = license_name.lower()
            if license_name[0-1] == 'cc':
                license_name = 'cc'
            elif license_name[0-3] == 'gpl':
                license_name = 'gpl'
            elif license_name[0-3] == 'odb':
                license_name = 'odb'
            else:
                license_name = 'other'
        self._license_name = license_name

    @property
    def subtitle(self):
        """Gets the subtitle of this DatasetNewRequest.  # noqa: E501

        The subtitle to be set on the dataset  # noqa: E501

        :return: The subtitle of this DatasetNewRequest.  # noqa: E501
        :rtype: str
        """
        return self._subtitle

    @subtitle.setter
    def subtitle(self, subtitle):
        """Sets the subtitle of this DatasetNewRequest.

        The subtitle to be set on the dataset  # noqa: E501

        :param subtitle: The subtitle of this DatasetNewRequest.  # noqa: E501
        :type: str
        """

        self._subtitle = subtitle

    @property
    def description(self):
        """Gets the description of this DatasetNewRequest.  # noqa: E501

        The description to be set on the dataset  # noqa: E501

        :return: The description of this DatasetNewRequest.  # noqa: E501
        :rtype: str
        """
        return self._description

    @description.setter
    def description(self, description):
        """Sets the description of this DatasetNewRequest.

        The description to be set on the dataset  # noqa: E501

        :param description: The description of this DatasetNewRequest.  # noqa: E501
        :type: str
        """

        self._description = description

    @property
    def files(self):
        """Gets the files of this DatasetNewRequest.  # noqa: E501

        A list of files that should be associated with the dataset  # noqa: E501

        :return: The files of this DatasetNewRequest.  # noqa: E501
        :rtype: list[UploadFile]
        """
        return self._files

    @files.setter
    def files(self, files):
        """Sets the files of this DatasetNewRequest.

        A list of files that should be associated with the dataset  # noqa: E501

        :param files: The files of this DatasetNewRequest.  # noqa: E501
        :type: list[UploadFile]
        """
        if files is None:
            raise ValueError("Invalid value for `files`, must not be `None`")  # noqa: E501

        self._files = files

    @property
    def is_private(self):
        """Gets the is_private of this DatasetNewRequest.  # noqa: E501

        Whether or not the dataset should be private  # noqa: E501

        :return: The is_private of this DatasetNewRequest.  # noqa: E501
        :rtype: bool
        """
        return self._is_private

    @is_private.setter
    def is_private(self, is_private):
        """Sets the is_private of this DatasetNewRequest.

        Whether or not the dataset should be private  # noqa: E501

        :param is_private: The is_private of this DatasetNewRequest.  # noqa: E501
        :type: bool
        """

        self._is_private = is_private

    @property
    def convert_to_csv(self):
        """Gets the convert_to_csv of this DatasetNewRequest.  # noqa: E501

        Whether or not a tabular dataset should be converted to csv  # noqa: E501

        :return: The convert_to_csv of this DatasetNewRequest.  # noqa: E501
        :rtype: bool
        """
        return self._convert_to_csv

    @convert_to_csv.setter
    def convert_to_csv(self, convert_to_csv):
        """Sets the convert_to_csv of this DatasetNewRequest.

        Whether or not a tabular dataset should be converted to csv  # noqa: E501

        :param convert_to_csv: The convert_to_csv of this DatasetNewRequest.  # noqa: E501
        :type: bool
        """

        self._convert_to_csv = convert_to_csv

    @property
    def category_ids(self):
        """Gets the category_ids of this DatasetNewRequest.  # noqa: E501

        A list of tag IDs to associated with the dataset  # noqa: E501

        :return: The category_ids of this DatasetNewRequest.  # noqa: E501
        :rtype: list[str]
        """
        return self._category_ids

    @category_ids.setter
    def category_ids(self, category_ids):
        """Sets the category_ids of this DatasetNewRequest.

        A list of tag IDs to associated with the dataset  # noqa: E501

        :param category_ids: The category_ids of this DatasetNewRequest.  # noqa: E501
        :type: list[str]
        """

        self._category_ids = category_ids

    def to_dict(self):
        """Returns the model properties as a dict"""
        result = {}

        for attr, _ in six.iteritems(self.project_types):
            value = getattr(self, attr)
            if isinstance(value, list):
                result[attr] = list(map(
                    lambda x: x.to_dict() if hasattr(x, "to_dict") else x,
                    value
                ))
            elif hasattr(value, "to_dict"):
                result[attr] = value.to_dict()
            elif isinstance(value, dict):
                result[attr] = dict(map(
                    lambda item: (item[0], item[1].to_dict())
                    if hasattr(item[1], "to_dict") else item,
                    value.items()
                ))
            else:
                result[attr] = value

        return result

    def to_str(self):
        """Returns the string representation of the model"""
        return pprint.pformat(self.to_dict())

    def __repr__(self):
        """For `print` and `pprint`"""
        return self.to_str()

    def __eq__(self, other):
        """Returns true if both objects are equal"""
        if not isinstance(other, DatasetNewRequest):
            return False

        return self.__dict__ == other.__dict__

    def __ne__(self, other):
        """Returns true if both objects are not equal"""
        return not self == other

